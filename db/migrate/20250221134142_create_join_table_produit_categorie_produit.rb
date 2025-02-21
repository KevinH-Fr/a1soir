class CreateJoinTableProduitCategorieProduit < ActiveRecord::Migration[7.1]
  def change
    create_join_table :produits, :categorie_produits do |t|
      t.index :produit_id
      t.index :categorie_produit_id
    end
  end
end
