class AddStripeContentToProduits < ActiveRecord::Migration[7.1]
  def change
    add_column :produits, :stripe_product_id, :string
    add_column :produits, :stripe_price_id, :string
  end
end
