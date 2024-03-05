class CreateEnsembles < ActiveRecord::Migration[7.1]
  def change
    create_table :ensembles do |t|

      t.references :produit, null: false, foreign_key: true
      t.references :type_produit1, null: false, foreign_key: { to_table: :type_produits }
      t.references :type_produit2, null: false, foreign_key: { to_table: :type_produits }

      t.timestamps
    end
  end
end
