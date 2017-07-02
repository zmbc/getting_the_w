class Team < ApplicationRecord
  has_many :shots

  has_many :home_games, class_name: 'Game', foreign_key: 'home_team_id'
  has_many :away_games, class_name: 'Game', foreign_key: 'visiting_team_id'

  def full_name
    "#{city} #{name}"
  end
end
