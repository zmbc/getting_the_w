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
      .group('(3 * round(loc_x / 3))')
      .group('(3 * round(loc_y / 3))')
      .group(:made)
      .count

    groups_to_hashes raw_groups
  end

  private

  def groups_to_hashes(raw_groups)
    result = {}

    raw_groups.each do |key, amount|
      loc_x = key[0]
      loc_y = key[1]
      made = key[2]
      result[loc_x] ||= {}
      result[loc_x][loc_y] ||= {}
      result[loc_x][loc_y][made ? 'made' : 'missed'] = amount
    end

    result
  end
end
