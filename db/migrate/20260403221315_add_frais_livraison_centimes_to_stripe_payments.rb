class AddFraisLivraisonCentimesToStripePayments < ActiveRecord::Migration[7.1]
  def change
    add_column :stripe_payments, :frais_livraison_centimes, :integer
  end
end
