class AddUniqueIndexToStripeIdsOnProduits < ActiveRecord::Migration[7.1]
  def up
    unless index_exists?(:produits, :stripe_price_id, name: "index_produits_on_stripe_price_id_unique")
      add_index :produits, :stripe_price_id,
                unique: true,
                where: "stripe_price_id IS NOT NULL",
                name: "index_produits_on_stripe_price_id_unique"
    end

    unless index_exists?(:produits, :stripe_product_id, name: "index_produits_on_stripe_product_id_unique")
      add_index :produits, :stripe_product_id,
                unique: true,
                where: "stripe_product_id IS NOT NULL",
                name: "index_produits_on_stripe_product_id_unique"
    end
  end

  def down
    remove_index :produits, name: "index_produits_on_stripe_price_id_unique", if_exists: true
    remove_index :produits, name: "index_produits_on_stripe_product_id_unique", if_exists: true
  end
end
