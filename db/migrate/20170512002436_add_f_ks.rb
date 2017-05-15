class AddFKs < ActiveRecord::Migration[5.1]
  def change
    add_reference :players, :team, foreign_key: true
    add_reference :shots, :game, foreign_key: true
  end
end
