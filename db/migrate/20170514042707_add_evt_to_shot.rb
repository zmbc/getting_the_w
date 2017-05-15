class AddEvtToShot < ActiveRecord::Migration[5.1]
  def change
    add_column :shots, :evt, :integer
  end
end
