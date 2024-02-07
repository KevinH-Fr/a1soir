class CreateArticles < ActiveRecord::Migration[7.1]
  def change
    create_table :articles do |t|
      t.integer :quantite
      t.decimal :prix
      t.decimal :total
      t.references :produit, null: false, foreign_key: true
      t.references :commande, null: false, foreign_key: true
      t.string :locvente
      t.decimal :caution
      t.decimal :totalcaution
      t.boolean :longueduree
      t.text :commentaires

      t.timestamps
    end
  end
end
