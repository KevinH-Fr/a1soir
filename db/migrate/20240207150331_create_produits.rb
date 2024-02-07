class CreateProduits < ActiveRecord::Migration[7.1]
  def change
    create_table :produits do |t|
      t.string :nom
      t.decimal :prixvente
      t.decimal :prixlocation
      t.text :description
      t.references :categorie_produit, null: false, foreign_key: true
      t.decimal :caution
      t.string :handle
      t.string :reffrs
      t.integer :quantite
      t.references :fournisseur, null: false, foreign_key: true
      t.date :dateachat
      t.decimal :prixachat

      t.timestamps
    end
  end
end
