class AddConvertiLeToCommandes < ActiveRecord::Migration[7.1]
  def change
    add_column :commandes, :converti_le, :datetime
    add_index :commandes, :converti_le
  end
end
