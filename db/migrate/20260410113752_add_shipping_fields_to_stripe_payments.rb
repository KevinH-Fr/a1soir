class AddShippingFieldsToStripePayments < ActiveRecord::Migration[7.1]
  def change
    add_column :stripe_payments, :shipping_name, :string
    add_column :stripe_payments, :shipping_address_line1, :string
    add_column :stripe_payments, :shipping_address_line2, :string
    add_column :stripe_payments, :shipping_city, :string
    add_column :stripe_payments, :shipping_postal_code, :string
    add_column :stripe_payments, :shipping_country, :string
    add_column :stripe_payments, :customer_phone, :string
  end
end
