class AddAncienPrixventeToProduits < ActiveRecord::Migration[7.1]
  def change
    add_column :produits, :ancien_prixvente, :decimal
  end
end
