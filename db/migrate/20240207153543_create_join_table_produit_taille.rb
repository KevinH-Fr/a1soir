class CreateJoinTableProduitTaille < ActiveRecord::Migration[7.1]
  def change
    create_join_table :produits, :tailles do |t|
       t.index [:produit_id, :taille_id]
       t.index [:taille_id, :produit_id]
    end
  end
end
