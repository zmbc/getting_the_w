class Player < ApplicationRecord
  belongs_to :team

  has_many :shots

  has_many :on_courts
  has_many :shots_on_court, through: :on_courts, source: :shot

  def full_name
    "#{self.first_name} #{self.last_name}"
  end

  def shot_distribution_and_accuracy(season)
    raw_groups = self.shots
      .joins(:game)
      .where(games: {date: Date.new(season)..Date.new(season).end_of_year})
      .group('(2 * round(loc_x / 20))')
      .group('(2 * round(loc_y / 20))')
      .group(:made)
      .group(:three)
      .count

    groups_to_hashes raw_groups
  end

  def team_shot_deltas_distribution(season)
    games = self.shots_on_court
      .joins(:game)
      .where(games: {date: Date.new(season)..Date.new(season).end_of_year})
      .map {|x| x.game_id}
      .uniq

    # BUG: If a player has played for two teams within a season, and they have
    # played each other, both will be counted as this player's team.
    # It's totally possible to fix this by checking on a game-by-game basis which
    # team a player was playing on, but it is SLOW.
    teams = games.map do |game|
      self.shots_on_court
        .where(on_courts: {offense: true})
        .where(game_id: game)
        .first
        .team_id
    end

    on_court = self.shots_on_court.where(on_courts: {offense: true})
      .where(game_id: games)
      .group('(7 * round(loc_x / 70))')
      .group('(7 * round(loc_y / 70))')
      .group(:made)
      .group(:three)
      .count

    off_court = Shot
      .where(game_id: games, team_id: teams)
      .where.not(id: self.shots_on_court.ids)
      .group('(7 * round(loc_x / 70))')
      .group('(7 * round(loc_y / 70))')
      .group(:made)
      .group(:three)
      .count

    deltas(on_court, off_court)
  end

  def opposing_team_shot_deltas_distribution(season)
    games = self.shots_on_court
      .joins(:game)
      .where(games: {date: Date.new(season)..Date.new(season).end_of_year})
      .map {|x| x.game_id}
      .uniq

    # BUG: If a player has played for two teams within a season, and they have
    # played each other, neither will be counted as this player's opposing team.
    # It's totally possible to fix this by checking on a game-by-game basis which
    # team a player was playing on, but it is SLOW.
    teams = games.map do |game|
      self.shots_on_court
        .where(on_courts: {offense: true})
        .where(game_id: game)
        .first
        .team_id
    end

    on_court = Shot
      .where(game_id: games)
      .where(id: self.shots_on_court.where(on_courts: {offense: false}).ids)
      .group('(7 * round(loc_x / 70))')
      .group('(7 * round(loc_y / 70))')
      .group(:made)
      .group(:three)
      .count

    off_court = Shot
      .where(game_id: games)
      .where.not(team_id: teams)
      .where.not(id: self.shots_on_court.ids)
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

    on_court_count = on_court.map {|x| x[:made] + x[:missed]}.sum
    off_court_count = off_court.map {|x| x[:made] + x[:missed]}.sum

    puts 'on court count: ' + on_court_count.to_s
    puts 'off court count: ' + off_court_count.to_s

    on_court.each {|a| a[:on_court] = true}
    off_court.each {|a| a[:on_court] = false}

    (on_court + off_court)
      .group_by{|h| [h[:x], h[:y]]}
      .map do |k, v|
        puts 'key: ' + k.to_s if k == [0, 0]
        puts 'value: ' + v.to_s if k == [0, 0]
        on_court_for_loc = v.find {|x| x[:on_court]} || {made: 0, missed: 0, pts_per_shot: 0}
        off_court_for_loc = v.find {|x| !x[:on_court]} || {made: 0, missed: 0, pts_per_shot: 0}

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
      loc_x = key[0]
      loc_y = key[1]
      made = key[2]
      three = key[3]
      result_item = result.find { |item| item[:x] == loc_x && item[:y] == loc_y }
      if !result_item
        # At first, pts_per_shot is actually total points
        result_item = {x: loc_x, y: loc_y, made: 0, missed: 0, pts_per_shot: 0}
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
