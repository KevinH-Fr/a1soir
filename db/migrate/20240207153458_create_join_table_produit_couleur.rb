class CreateJoinTableProduitCouleur < ActiveRecord::Migration[7.1]
  def change
    create_join_table :produits, :couleurs do |t|
       t.index [:produit_id, :couleur_id]
       t.index [:couleur_id, :produit_id]
    end
  end
end
