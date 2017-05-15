class CreateOnCourts < ActiveRecord::Migration[5.1]
  def change
    create_table :on_courts do |t|
      t.references :player, foreign_key: true
      t.references :shot, foreign_key: true
      t.boolean :offense

      t.timestamps
    end
  end
end
