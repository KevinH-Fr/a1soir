class UpdateProduitsColumns < ActiveRecord::Migration[7.1]
  def change
    change_column_null :produits, :categorie_produit_id, true
    change_column_null :produits, :fournisseur_id, true
  end
end
