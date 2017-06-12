require 'net/http'
require 'json'

namespace :scrape do
  task :season, [:year] => :environment do |t, args|
    scrape_season(args[:year])
  end

  desc "Scrape the current (calendar year) season"
  task current_season: :environment do
    scrape_season(Time.now.year)
  end

  desc "Scrape the last day"
  task last_day: :environment do
    now = Time.now
    if now.day == 1 && now.month == 1
      schedule = month_schedule(now.year - 1, 12)
    elsif now.day == 1
      schedule = month_schedule(now.year, now.month - 1)
    else
      schedule = month_schedule(now.year, now.month)
    end

    schedule['mscd']['g'].each do |game|
      game_date = Date.parse(game['gdte'])
      if game_date >= now.to_date - 1 && game_date <= now.to_date
        scrape_game(game, now.year)
      end
    end
  end

  task update_unknowns: :environment do
    unknowns = Player.where(first_name: "Unknown")
    unknowns.each do |p|
      wait_a_sec
      season = 2016
      uri = URI("http://data.wnba.com/data/5s/v2015/json/mobile_teams/wnba/#{season}/players/playercard_#{p.id}_01.json")
      res = Net::HTTP.get(uri)
      if !res.empty?
        json = JSON.parse(res)
        p.first_name = json['pl']['fn']
        p.last_name = json['pl']['ln']
        p.position = json['pl']['pos']
        p.team_id = json['pl']['tid']
        p.save!
      end
    end
  end

  task remove_unnecessary_players: :environment do
    Player
      .select("count(players.id), players.id")
      .left_joins(:on_courts)
      .group("players.id")
      .having("count(on_courts.id) = 0")
      .destroy_all
  end
end

def scrape_season(season)
  (1..12).each do |month|
    schedule = month_schedule(season, month)
    schedule['mscd']['g'].each do |game|
      wait_a_sec
      scrape_game(game, season)
    end
    wait_a_sec
  end
end

def month_schedule(year, month)
  uri = URI("http://data.wnba.com/data/5s/v2015/json/mobile_teams/wnba/#{year.to_s}/league/10_league_schedule_#{month.to_s.rjust(2, "0")}.json")
  JSON.parse(Net::HTTP.get(uri))
end

def scrape_game(game_data, season)
  home_team_id = game_data['h']['tid']
  away_team_id = game_data['v']['tid']

  home_team = Team.find_or_initialize_by(id: home_team_id)
  home_team.city = game_data['h']['tc']
  home_team.name = game_data['h']['tn']
  home_team.save!

  away_team = Team.find_or_initialize_by(id: away_team_id)
  away_team.city = game_data['v']['tc']
  away_team.name = game_data['v']['tn']
  away_team.save!

  game = Game.find_or_initialize_by(id: game_data['gid'])
  game.home_team = home_team
  game.visiting_team = away_team
  game.date = Date.parse(game_data['gdte'])
  game.save!

  scrape_shots(game.id, game.home_team_id, game.visiting_team_id, season)
end

def scrape_shots(game_id, home_id, away_id, season)
  # Handles up to 3 overtimes
  (1..7).each do |period|
    uri = URI("http://data.wnba.com/data/v2015/json/mobile_teams/wnba/#{season}/scores/pbp/#{game_id}_#{period}_pbp.json")
    res = Net::HTTP.get(uri)
    # Res empty when we get a 404, i.e. when this period doesn't exist
    break if res.empty?

    play_by_play = JSON.parse(res)
    # Plays aren't there for games that haven't started yet
    parse_period(play_by_play, home_id, away_id, season) if play_by_play['g']['pla']
    wait_a_sec
  end
end

def parse_period(play_by_play, home_id, away_id, season)
  on_duplicate_key_update = [
    :made,
    :loc_x,
    :loc_y,
    :period,
    :seconds_remaining,
    :player_id,
    :team_id,
    :game_id,
    :evt,
    :three
  ]

  home_players = get_starting_lineup(play_by_play, home_id, season)
  away_players = get_starting_lineup(play_by_play, away_id, season)
  game_id = play_by_play['g']['gid']
  shots = []
  play_by_play['g']['pla'].each do |play|
    if play['etype'].in? [1, 2]
      # Made and missed shots, respectively
      shot = Shot.new({
        evt: play['evt'],
        game_id: game_id
      })
      shot.made = (play['etype'] == 1)
      shot.loc_x = play['locX']
      shot.loc_y = play['locY']
      shot.period = play_by_play['g']['p']
      split_clock = play['cl'].split(":")
      shot.seconds_remaining = (split_clock[0].to_i * 60) + split_clock[1].to_i
      shot.three = (play['opt1'] == 3)
      shot.player_id = player_id play['pid']
      shot.team_id = play['tid']
      shot.game_id = game_id

      if shot.team_id == home_id
        shot.offensive_players = home_players
        shot.defensive_players = away_players
      else
        shot.defensive_players = home_players
        shot.offensive_players = away_players
      end

      shots.push shot
    elsif play['etype'] == 8
      # Substitution
      leaving_player = find_or_create_player(player_id(play['pid']), season)
      entering_player = find_or_create_player(player_id(play['epid']), season)
      players = (play['tid'] == home_id) ? home_players : away_players
      if i = players.index(leaving_player)
        players[i] = entering_player
      else
        Rails.logger.warn "A player left that we didn't think was in the game! player: #{leaving_player.id} game: #{game_id} period: #{period}"
        players.push entering_player
      end
    end
  end

  # Uses activerecord-import to do everything at once. This will generate one
  # big insert. Note that some of the shots are already in the database, but the
  # insert fails because the unique id is the same (and also the game_id + evt unique index).
  # The way activerecord-import works, when a uniqueness constraint is violated,
  # you can select which things to update (by default it's just updated_at).
  # We want to update everything. We won't often be re-scraping the same game,
  # so this isn't a huge perf issue.
  Shot.import shots, on_duplicate_key_update: on_duplicate_key_update
end

def get_starting_lineup(play_by_play, team_id, season)
  starting_lineup = []
  non_starters_on_court = []
  play_by_play['g']['pla'].each do |play|
    if play['etype'] == 8 && play['tid'] == team_id
      # Substitution
      leaving_player = player_id(play['pid'])
      entering_player = player_id(play['epid'])
      if non_starters_on_court.index(leaving_player)
        # This player is not a starter
        non_starters_on_court.delete(leaving_player)
      elsif !starting_lineup.index(leaving_player)
        # We found a starter!
        starting_lineup.push leaving_player
      end

      non_starters_on_court.push entering_player
    end
  end

  non_starters_on_court = []
  if starting_lineup.length < 5
    # Okay, looks like not everyone who started ended up getting subbed out.
    # Now we make the second pass looking for any activity.
    play_by_play['g']['pla'].each do |play|
      if play['etype'] == 8
        # Substitution
        leaving_player = player_id(play['pid'])
        entering_player = player_id(play['epid'])
        if non_starters_on_court.index(leaving_player)
          # This player is not a starter leaving for the first time
          non_starters_on_court.delete(leaving_player)
        end

        non_starters_on_court.push entering_player
      elsif play['tid'] == team_id
        players_involved = []

        # Coaches can do events that end up in the play by play, like get a technical
        players_involved.push(player_id(play['pid'])) unless could_be_a_coach(play)

        # etype == 10 is a jump ball. In that case, epid is the player who
        # recovers the ball, who can be on either team.
        players_involved.push(player_id(play['epid'])) unless play['etype'] == 10

        players_involved.each do |player|
          if player && player != 0 && !non_starters_on_court.index(player) && !starting_lineup.index(player)
            # Someone did something who wasn't subbed in! They must be a starter!
            starting_lineup.push player
          end
        end
      elsif play['tid'] != 0
        # Other team's event
        player = player_id play['opid']
        if player && player != 0 && !non_starters_on_court.index(player) && !starting_lineup.index(player)
          # opid's seem to have occasional problems (like plays where players are
          # supposedly fouling their teammates). In an effort to guard against this,
          # we make sure this player hasn't done any primary actions for the other team.
          other_team_actions = play_by_play['g']['pla'].select do |p|
            p['pid'] == player && p['tid'] != team_id && p['tid'] != 0
          end

          if other_team_actions.empty?
            # Someone did something who wasn't subbed in! They must be a starter!
            starting_lineup.push player
          else
            Rails.logger.warn "In game #{play_by_play['g']['gid']} period #{play_by_play['g']['p']}, player #{player} has conflicting opid!"
          end
        end
      end
    end
  end

  if starting_lineup.length != 5
    Rails.logger.warn "Weird starting lineup situation for game #{play_by_play['g']['gid']}!"
  end

  starting_lineup.map do |id|
    find_or_create_player(id, season)
  end
end

def could_be_a_coach(play)
  # Technical foul (6: foul, 11: technical)
  (play['etype'] == 6 && play['mtype'] == 11) ||
    # Ejection
    play['etype'] == 11
end

def find_or_create_player(id, season)
  id = player_id(id)

  player = Player.find_by_id id

  return player if player

  wait_a_sec

  uri = URI("http://data.wnba.com/data/5s/v2015/json/mobile_teams/wnba/#{season}/players/playercard_#{id}_01.json")
  res = Net::HTTP.get(uri)
  if res.empty?
    # This is a duplicate/corrupted player
    json = {
      'pl' => {
        'id' => id,
        'fn' => "Unknown",
        'ln' => "Player",
        'pos' => "Unknown",
        'tid' => Team.find_or_create_by(city: "Unknown", name: "Unknown").id
      }
    }
  else
    json = JSON.parse(res)
  end

  player = Player.new({
      id: id,
      first_name: json['pl']['fn'],
      last_name: json['pl']['ln'],
      position: json['pl']['pos'],
      team_id: json['pl']['tid']
    })
  player.save!

  return player
end

def wait_a_sec
  sleep rand(1..3)
end

def player_id(id)
  id = id.to_i
  known_dupes = {
    1628244 => 202288
  }
  id = known_dupes[id] if known_dupes.key? id
  return id
end

# http://data.wnba.com/data/5s/v2015/json/mobile_teams/wnba/2017/league/10_league_schedule_06.json
# http://data.wnba.com/data/5s/v2015/json/mobile_teams/wnba/2015/players/playercard_203025_02.json
# http://data.wnba.com/data/5s/v2015/json/mobile_teams/wnba/2017/players/10_historical_players.json
# http://data.wnba.com/data/5s/v2015/json/mobile_teams/wnba/2017/players/10_player_info.json
# http://data.wnba.com/data/v2015/json/mobile_teams/wnba/2017/scores/pbp/1011700012_2_pbp.json
