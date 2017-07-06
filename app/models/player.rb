class Player < ApplicationRecord
  belongs_to :team

  has_many :shots

  has_many :on_courts
  has_many :shots_on_court, through: :on_courts, source: :shot

  def self.remove_unnecessary!
    select('count(players.id), players.id')
      .left_joins(:on_courts)
      .group('players.id')
      .having('count(on_courts.id) = 0')
      .destroy_all
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def position_friendly
    position.sub('G', 'Guard')
      .sub('F', 'Forward')
      .sub('C', 'Center')
      .sub('-', '/')
  end

  def shot_distribution_and_accuracy(season)
    raw_groups = shots
                 .joins(:game)
                 .where.not(loc_x: nil)
                 .where.not(loc_y: nil)
                 .where(games: { date: Date.new(season)..Date.new(season).end_of_year })
                 .group('(2 * round(loc_x / 20))')
                 .group('(2 * round(loc_y / 20))')
                 .group(:made)
                 .group(:three)
                 .count

    groups_to_hashes raw_groups
  end

  def distance_distribution_and_accuracy(season)
    raw_groups = shots
                 .joins(:game)
                 .where.not(loc_x: nil)
                 .where.not(loc_y: nil)
                 .where(games: { date: Date.new(season)..Date.new(season).end_of_year })
                 .group('round(sqrt(pow(loc_x / 10, 2) + pow(loc_y / 10, 2)) / 2) * 2')
                 .group(:made)
                 .group(:three)
                 .count

    distance_groups_to_hashes raw_groups
  end

  def game_time_distribution_and_accuracy(season)
    raw_groups = shots
                 .joins(:game)
                 .where.not(loc_x: nil)
                 .where.not(loc_y: nil)
                 .where(games: { date: Date.new(season)..Date.new(season).end_of_year })
                 .group('round((((period - 1) * 600) + (600 - seconds_remaining)) / 120) * 2')
                 .group(:made)
                 .group(:three)
                 .count

    game_time_groups_to_hashes raw_groups
  end

  def team_shot_deltas_distribution(season)
    games = shots_on_court
            .joins(:game)
            .where(games: { date: Date.new(season)..Date.new(season).end_of_year })
            .map(&:game_id)
            .uniq

    # BUG: If a player has played for two teams within a season, and they have
    # played each other, both will be counted as this player's team.
    # It's totally possible to fix this by checking on a game-by-game basis
    # which team a player was playing on, but it is SLOW.
    teams = games.map do |game|
      shots_on_court
        .find_by(on_courts: { offense: true }, game_id: game)
        .team_id
    end

    on_court = shots_on_court.where(on_courts: { offense: true })
                             .where.not(loc_x: nil)
                             .where.not(loc_y: nil)
                             .where(game_id: games)
                             .group('(7 * round(loc_x / 70))')
                             .group('(7 * round(loc_y / 70))')
                             .group(:made)
                             .group(:three)
                             .count

    off_court = Shot
                .where(game_id: games, team_id: teams)
                .where.not(id: shots_on_court.ids)
                .where.not(loc_x: nil)
                .where.not(loc_y: nil)
                .group('(7 * round(loc_x / 70))')
                .group('(7 * round(loc_y / 70))')
                .group(:made)
                .group(:three)
                .count

    deltas(on_court, off_court)
  end

  def opposing_team_shot_deltas_distribution(season)
    games = shots_on_court
            .joins(:game)
            .where(games: { date: Date.new(season)..Date.new(season).end_of_year })
            .map(&:game_id)
            .uniq

    # BUG: If a player has played for two teams within a season, and they have
    # played each other, neither will be counted as this player's opposing team.
    # It's totally possible to fix this by checking on a game-by-game basis which
    # team a player was playing on, but it is SLOW.
    teams = games.map do |game|
      shots_on_court
        .find_by(on_courts: { offense: true }, game_id: game)
        .team_id
    end

    on_court = Shot
               .where(game_id: games)
               .where(id: shots_on_court.where(on_courts: { offense: false }).ids)
               .where.not(loc_x: nil)
               .where.not(loc_y: nil)
               .group('(7 * round(loc_x / 70))')
               .group('(7 * round(loc_y / 70))')
               .group(:made)
               .group(:three)
               .count

    off_court = Shot
                .where(game_id: games)
                .where.not(team_id: teams)
                .where.not(id: shots_on_court.ids)
                .where.not(loc_x: nil)
                .where.not(loc_y: nil)
                .group('(7 * round(loc_x / 70))')
                .group('(7 * round(loc_y / 70))')
                .group(:made)
                .group(:three)
                .count

    deltas(on_court, off_court)
  end

  private

  def deltas(on_court, off_court)
    on_court = groups_to_hashes(on_court)
    off_court = groups_to_hashes(off_court)

    on_court_count = on_court.map { |x| x[:made] + x[:missed] }.sum
    off_court_count = off_court.map { |x| x[:made] + x[:missed] }.sum

    on_court.each { |a| a[:on_court] = true }
    off_court.each { |a| a[:on_court] = false }

    (on_court + off_court)
      .group_by { |h| [h[:x], h[:y]] }
      .map do |k, v|
        on_court_for_loc = v.find { |x| x[:on_court] } || { made: 0, missed: 0, pts_per_shot: 0 }
        off_court_for_loc = v.find { |x| !x[:on_court] } || { made: 0, missed: 0, pts_per_shot: 0 }

        loc_x = k[0]
        loc_y = k[1]

        [on_court_for_loc, off_court_for_loc].each do |h|
          next if h.nil?
          h.delete(:on_court)
          h.delete(:x)
          h.delete(:y)
        end

        on_court_for_loc[:frequency] =
          (on_court_for_loc[:made] + on_court_for_loc[:missed] || 0) / on_court_count.to_f
        off_court_for_loc[:frequency] =
          (off_court_for_loc[:made] + off_court_for_loc[:missed] || 0) / off_court_count.to_f

        {
          on_court: on_court_for_loc,
          off_court: off_court_for_loc,
          frequency_delta: on_court_for_loc[:frequency] - off_court_for_loc[:frequency],
          pps_delta: on_court_for_loc[:pts_per_shot] - off_court_for_loc[:pts_per_shot],
          x: loc_x,
          y: loc_y
        }
      end.compact
  end

  def groups_to_hashes(raw_groups)
    result = []

    raw_groups.each do |key, amount|
      loc_x, loc_y, made, three = key
      result_item = result.find { |item| item[:x] == loc_x && item[:y] == loc_y }
      unless result_item
        # At first, pts_per_shot is actually total points
        result_item = { x: loc_x, y: loc_y, made: 0, missed: 0, pts_per_shot: 0 }
        result.push result_item
      end
      result_item[made ? :made : :missed] += amount
      result_item[:pts_per_shot] += amount * (three ? 3 : 2) if made
    end

    result.each do |x|
      x[:pts_per_shot] = x[:pts_per_shot].to_f / (x[:made] + x[:missed])
    end

    result
  end

  def distance_groups_to_hashes(raw_groups)
    result = []

    raw_groups.each do |key, amount|
      distance, made, three = key
      result_item = result.find { |item| item[:distance] == distance }
      unless result_item
        # At first, pts_per_shot is actually total points
        result_item = { distance: distance, made: 0, missed: 0, pts_per_shot: 0 }
        result.push result_item
      end
      result_item[made ? :made : :missed] += amount
      result_item[:pts_per_shot] += amount * (three ? 3 : 2) if made
    end

    result.each do |x|
      x[:pts_per_shot] = x[:pts_per_shot].to_f / (x[:made] + x[:missed])
    end

    result
  end

  def game_time_groups_to_hashes(raw_groups)
    result = []

    raw_groups.each do |key, amount|
      minutes, made, three = key
      result_item = result.find { |item| item[:minutes] == minutes }
      unless result_item
        # At first, pts_per_shot is actually total points
        result_item = { minutes: minutes, made: 0, missed: 0, pts_per_shot: 0 }
        result.push result_item
      end
      result_item[made ? :made : :missed] += amount
      result_item[:pts_per_shot] += amount * (three ? 3 : 2) if made
    end

    result.each do |x|
      x[:pts_per_shot] = x[:pts_per_shot].to_f / (x[:made] + x[:missed])
    end

    result
  end
end
