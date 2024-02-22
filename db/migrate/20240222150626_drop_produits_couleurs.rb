class DropProduitsCouleurs < ActiveRecord::Migration[7.1]
  def change
    drop_join_table :produits, :couleurs
  end
end
