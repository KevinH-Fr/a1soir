class ChangeTypeLocVenteToCommandes < ActiveRecord::Migration[7.1]
  def change
    change_column :commandes, :type_locvente, :string
  end
end
