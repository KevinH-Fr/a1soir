class CreateStripePayments < ActiveRecord::Migration[7.1]
  def change
    create_table :stripe_payments do |t|
      t.string :stripe_payment_id
      t.references :produit, null: false, foreign_key: true
      t.integer :amount
      t.string :currency
      t.string :status
      t.string :payment_method
      t.string :charge_id

      t.timestamps
    end
  end
end
