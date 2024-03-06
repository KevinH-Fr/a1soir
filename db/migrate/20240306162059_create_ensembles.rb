class CreateEnsembles < ActiveRecord::Migration[7.1]
  def change
    create_table :ensembles do |t|

      t.references :produit, null: true, foreign_key: true
      t.references :type_produit1, null: true, foreign_key: { to_table: :type_produits }
      t.references :type_produit2, null: true, foreign_key: { to_table: :type_produits }
      t.references :type_produit3, null: true, foreign_key: { to_table: :type_produits }
      t.references :type_produit4, null: true, foreign_key: { to_table: :type_produits }
      t.references :type_produit5, null: true, foreign_key: { to_table: :type_produits }
      t.references :type_produit6, null: true, foreign_key: { to_table: :type_produits }

      t.timestamps
    end
  end
end
