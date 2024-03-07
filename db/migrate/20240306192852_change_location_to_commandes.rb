class ChangeLocationToCommandes < ActiveRecord::Migration[7.1]
  def change
    rename_column :commandes, :location, :type_locvente

  end
end
