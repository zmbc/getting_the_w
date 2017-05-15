class OnCourt < ApplicationRecord
  belongs_to :player
  belongs_to :shot
end
