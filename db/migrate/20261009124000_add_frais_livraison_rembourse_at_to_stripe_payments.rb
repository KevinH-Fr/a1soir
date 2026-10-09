class AddFraisLivraisonRembourseAtToStripePayments < ActiveRecord::Migration[7.2]
  def change
    add_column :stripe_payments, :frais_livraison_rembourse_at, :datetime
  end
end
