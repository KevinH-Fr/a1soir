class DropProduitsTailles < ActiveRecord::Migration[7.1]
  def change
    drop_join_table :produits, :tailles
  end
end
