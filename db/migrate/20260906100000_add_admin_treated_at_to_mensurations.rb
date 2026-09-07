class AddAdminTreatedAtToMensurations < ActiveRecord::Migration[7.2]
  def change
    add_column :mensurations, :admin_treated_at, :datetime
    add_index :mensurations, :admin_treated_at
  end
end
