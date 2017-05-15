class CreateGames < ActiveRecord::Migration[5.1]
  def change
    create_table :games do |t|
      t.references :home_team, references: :team
      t.references :visiting_team, references: :team
      t.date :date

      t.timestamps
    end
  end
end
