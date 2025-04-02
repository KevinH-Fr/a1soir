class CreateStripePaymentItems < ActiveRecord::Migration[7.1]
  def change
    create_table :stripe_payment_items do |t|
      t.references :stripe_payment, null: false, foreign_key: true
      t.references :produit, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.integer :unit_amount, null: false  # stored in cents

      t.timestamps
    end
  end
end
