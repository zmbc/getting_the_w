class UniqueShots < ActiveRecord::Migration[5.1]
  def change
    add_index :shots, [:game_id, :evt], unique: true
  end
end
