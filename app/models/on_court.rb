class OnCourt < ApplicationRecord
  belongs_to :player
  belongs_to :shot

  validates_uniqueness_of :player_id, scope: :shot_id
end
