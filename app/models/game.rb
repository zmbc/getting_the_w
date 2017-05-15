class Game < ApplicationRecord
  belongs_to :home_team, class_name: 'Team', foreign_key: 'home_team_id'
  belongs_to :visiting_team, class_name: 'Team', foreign_key: 'visiting_team_id'
end
