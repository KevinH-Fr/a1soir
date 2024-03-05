class AddTypeProduitToProduits < ActiveRecord::Migration[7.1]
  def change
    add_reference :produits, :type_produit, null: true, foreign_key: true
  end
end
