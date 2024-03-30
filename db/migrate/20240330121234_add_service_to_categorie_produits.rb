class AddServiceToCategorieProduits < ActiveRecord::Migration[7.1]
  def change
    add_column :categorie_produits, :service, :boolean
  end
end
