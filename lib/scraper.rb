# "Time is a created thing. To say 'I don't have time,' is like saying,
# 'I don't want to.'"

# We use the Date class for calculating date ranges.
require 'date'

# Scraper is the main interface for performing WNBA scraping tasks.
module Scraper
  # We alias the relevant models into a "DB" namespace to make it clear that
  # they represent our database tables, not their counterparts in the WNBA API.
  module DB
    Player = ::Player
    Team = ::Team
    Game = ::Game
    Shot = ::Shot
  end

  # Scraping an entire season is useful for easily backfilling.
  def self.scrape_season(season)
    schedules = API::MonthSchedule.get_all_from_season(season: season)
    scrape_schedules schedules
  end

  # Scraping the last X amount of time is useful for periodically updating the
  # database with the results of the latest action.
  def self.scrape_since(start)
    # Start is permitted to be either a Time or Date type.
    start = start.to_date if start.respond_to? :to_date
    year_month_tuples = (start..Time.zone.today)
                        .map { |d| [d.year, d.month] }.uniq

    schedules = year_month_tuples.map do |year, month|
      API::MonthSchedule.get(season: year, month: month)
    end

    schedules.each do |schedule|
      schedule.games
              .select { |g| g.date >= start && g.date < Time.zone.today }
              .each { |g| scrape_game(g) }
    end
  end

  private_class_method def self.scrape_schedules(schedules)
    schedules.each do |schedule|
      scrape_schedule schedule
      Utility.wait_a_sec
    end
  end

  private_class_method def self.scrape_schedule(schedule)
    schedule.games
            .select { |game| game.date < Time.zone.today }
            .each do |game|
              Utility.wait_a_sec
              scrape_game game
            end
  end

  private_class_method def self.scrape_game(game)
    # We've probably seen the teams before, but it's far easier to just check
    # every time than to force a preliminary team-gathering step.
    overwrite_teams = game.season == Time.zone.today.year
    create_or_update_team(game.home_team, overwrite: overwrite_teams)
    create_or_update_team(game.away_team, overwrite: overwrite_teams)
    create_or_update_game game
    scrape_shots_from_game game
  end

  private_class_method def self.scrape_shots_from_game(game)
    play_by_play = API::PlayByPlay::Game.get game
    play_by_play.periods.each do |period|
      scrape_shots_from_period period
    end
  end

  # These are the fields we update when re-scraping an already-scraped shot.
  SHOT_UPDATE = %i[
    made
    loc_x
    loc_y
    period
    seconds_remaining
    player_id
    team_id
    game_id
    evt
    three
  ].freeze

  private_class_method def self.scrape_shots_from_period(period)
    home_id = period.game.home_team.id
    away_id = period.game.away_team.id

    # The API doesn't directly tell us which players started the period. So we
    # use an algorithm to make our best guess based on the play-by-play (99.9%
    # right)
    home_players = get_starting_lineup(period, home_id)
    away_players = get_starting_lineup(period, away_id)
    period.events.each do |event|
      if event.shot?
        create_shot(
          event: event,
          period: period,
          home_id: home_id,
          home_players: home_players,
          away_players: away_players
        )
      elsif event.type == :substitution
        players = event.team_id == home_id ? home_players : away_players
        players = perform_substitution(players: players,
                                       event: event,
                                       period: period)
        if event.team_id == home_id
          home_players = players
        else
          away_players = players
        end
      end
    end
  end

  private_class_method def self.perform_substitution(players: nil,
                                                     event: nil,
                                                     period: nil)
    leaving_player = find_or_create_player(event.player_id,
                                           period.game.season)
    entering_player = find_or_create_player(event.extra_player_id,
                                            period.game.season)
    unless players.include? leaving_player
      Rails.logger.warn "A player left that we didn't think was in the"\
                        "game! player: #{leaving_player.id} game:"\
                        "#{period.game.id} period: #{period.period_num}"
    end

    players.add entering_player
    players.delete leaving_player

    players
  end

  private_class_method def self.create_shot(
    event: nil,
    period: nil,
    home_id: nil,
    home_players: nil,
    away_players: nil
  )
    shot = DB::Shot.find_or_initialize_by(evt: event.index,
                                          game_id: period.game.id)
    shot.made = (event.type == :made_shot)
    shot.loc_x = event.loc_x
    shot.loc_y = event.loc_y
    shot.period = period.period_num
    shot.seconds_remaining = event.seconds_remaining
    shot.three = event.three?
    shot.player_id = event.player_id
    shot.team_id = event.team_id

    if shot.team_id == home_id
      shot.offensive_players = home_players.to_a
      shot.defensive_players = away_players.to_a
    else
      shot.offensive_players = away_players.to_a
      shot.defensive_players = home_players.to_a
    end

    shot.save!
  end

  private_class_method def self.get_starting_lineup(period, team_id)
    starting_lineup = Set.new
    # The first, and most reliable, pass is to check who got subbed out without
    # getting subbed in first. That's a pretty clear sign they started. But if
    # a player plays the whole period this pass won't find them.
    starting_lineup.merge(subbed_out_before_subbed_in(period, team_id))

    if starting_lineup.size < 5
      # Okay, looks like not everyone who started ended up getting subbed out.
      # Now we make the second pass looking for any activity at all (taking a
      # shot, getting a rebound, etc).
      starting_lineup.merge(did_anything(period, team_id))
    end

    if starting_lineup.size != 5
      # If both passes fail, we give up and stick with what we have.
      Rails.logger.warn 'Weird starting lineup situation for game '\
                        "#{period.game.id}!"
    end

    starting_lineup.map! do |id|
      find_or_create_player(id, period.game.season)
    end
  end

  private_class_method def self.subbed_out_before_subbed_in(period, team_id)
    result = Set.new
    non_starters_on_court = Set.new
    period.events.each do |event|
      next unless event.type == :substitution && event.team_id == team_id
      leaving_player = event.player_id
      entering_player = event.extra_player_id

      result.merge([leaving_player].to_set - non_starters_on_court)

      non_starters_on_court.delete leaving_player
      non_starters_on_court.add entering_player
    end

    result
  end

  private_class_method def self.did_anything(period, team_id)
    result = Set.new
    non_starters_on_court = Set.new
    period.events.each do |event|
      if event.type == :substitution
        leaving_player = event.player_id
        entering_player = event.extra_player_id

        non_starters_on_court.delete leaving_player
        non_starters_on_court.add entering_player
      elsif event.team_id == team_id
        players_involved_in(event).each do |player|
          next if !player || non_starters_on_court.include?(player)
          # Someone did something who wasn't subbed in! They must be a
          # starter!
          result.add player
        end
      elsif event.team_id
        # Other team's event
        player = event.opposing_player_id
        if player && !non_starters_on_court.include?(player)
          # opid's seem to have occasional problems (like plays where players
          # are supposedly fouling their teammates). In an effort to guard
          # against this, we make sure this player hasn't done any primary
          # actions for the other team.
          other_team_actions = period.events.select do |e|
            e.player_id == player && e.team_id && e.team_id != team_id
          end

          if other_team_actions.empty?
            # Someone did something who wasn't subbed in! They must be a
            # starter!
            result.add player
          else
            Rails.logger.warn "In game #{period.game.id}"\
                              " period #{period.period_num} player #{player}"\
                              ' has conflicting opid!'
          end
        end
      end
    end

    result
  end

  private_class_method def self.players_involved_in(event)
    result = Set.new

    # Coaches can do events that end up in the play by play, like get a
    # technical
    result.add event.player_id unless event.could_be_a_coach?

    # In a jump ball, extra_player_id is the player who
    # recovers the ball, who can be on either team.
    result.add event.extra_player_id unless event.type == :jump_ball

    result
  end

  private_class_method def self.find_or_create_player(id, season)
    player = DB::Player.find_by id: id

    return player if player

    Utility.wait_a_sec

    api_player = API::Player.get(id, season)

    player = DB::Player.new(id: id,
                            first_name: api_player.first_name,
                            last_name: api_player.last_name,
                            position: api_player.position,
                            team_id: api_player.team_id)
    player.save!

    player
  end

  private_class_method def self.create_or_update_team(api_team, overwrite: false)
    team = DB::Team.find_or_initialize_by(id: api_team.id)

    if overwrite
      team.city = api_team.city
      team.name = api_team.name
    else
      team.city ||= api_team.city
      team.name ||= api_team.name
    end

    team.save!
  end

  private_class_method def self.create_or_update_game(api_game)
    game = DB::Game.find_or_initialize_by(id: api_game.id)
    game.home_team_id = api_game.home_team.id
    game.visiting_team_id = api_game.away_team.id
    game.date = api_game.date
    game.save!
  end
end
