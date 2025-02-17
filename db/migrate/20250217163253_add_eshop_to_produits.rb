class AddEshopToProduits < ActiveRecord::Migration[7.1]
  def change
    add_column :produits, :eshop, :boolean
  end
end
