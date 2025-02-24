class AddPoidsToProduits < ActiveRecord::Migration[7.1]
  def change
    add_column :produits, :poids, :integer
  end
end
