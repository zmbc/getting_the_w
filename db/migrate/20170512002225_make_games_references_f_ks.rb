class MakeGamesReferencesFKs < ActiveRecord::Migration[5.1]
  def change
    add_foreign_key :games, :teams, column: :home_team_id
    add_foreign_key :games, :teams, column: :visiting_team_id
  end
end
