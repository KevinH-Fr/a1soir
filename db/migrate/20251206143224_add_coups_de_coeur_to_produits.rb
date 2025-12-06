class AddCoupsDeCoeurToProduits < ActiveRecord::Migration[7.1]
  def change
    add_column :produits, :coup_de_coeur, :boolean, default: false, null: false
    add_column :produits, :coup_de_coeur_position, :integer
    add_index :produits, [:coup_de_coeur, :coup_de_coeur_position]
  end
end
