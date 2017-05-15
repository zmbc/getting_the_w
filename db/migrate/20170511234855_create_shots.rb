class CreateShots < ActiveRecord::Migration[5.1]
  def change
    create_table :shots do |t|
      t.boolean :made
      t.integer :loc_x
      t.integer :loc_y
      t.integer :period
      t.integer :seconds_remaining
      t.references :player, foreign_key: true
      t.references :team, foreign_key: true

      t.timestamps
    end
  end
end
