class AddThreeToShots < ActiveRecord::Migration[5.1]
  def change
    add_column :shots, :three, :boolean
  end
end
