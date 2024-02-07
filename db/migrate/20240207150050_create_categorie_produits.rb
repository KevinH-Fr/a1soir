class CreateCategorieProduits < ActiveRecord::Migration[7.1]
  def change
    create_table :categorie_produits do |t|
      t.string :nom
      t.text :texte_annonce
      t.text :label

      t.timestamps
    end
  end
end
