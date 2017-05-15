class Player < ApplicationRecord
  belongs_to :team

  has_many :shots

  has_many :on_courts
  has_many :shots_on_court, through: :on_courts, source: :shot
end
