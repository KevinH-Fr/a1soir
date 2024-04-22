class AddActifToProduits < ActiveRecord::Migration[7.1]
  def change
    add_column :produits, :actif, :boolean
  end
end
