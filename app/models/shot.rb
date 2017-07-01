class Shot < ApplicationRecord
  belongs_to :player
  belongs_to :team
  belongs_to :game

  has_many :on_courts
  has_many :offensive_players, -> { where(on_courts: { offense: true }) }, through: :on_courts, source: :player
  has_many :defensive_players, -> { where(on_courts: { offense: false }) }, through: :on_courts, source: :player
end
