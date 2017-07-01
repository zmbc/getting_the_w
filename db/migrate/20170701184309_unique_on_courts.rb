class UniqueOnCourts < ActiveRecord::Migration[5.1]
  def change
    add_index :on_courts, [:player_id, :shot_id], :unique => true
  end
end
