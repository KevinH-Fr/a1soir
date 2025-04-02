class ChangeQuantityAndUnitAmountToNullableInStripePaymentItems < ActiveRecord::Migration[7.1]
  def change
    change_column_null :stripe_payment_items, :quantity, true
    change_column_null :stripe_payment_items, :unit_amount, true
  end
end
