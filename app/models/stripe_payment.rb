class StripePayment < ApplicationRecord
    belongs_to :produit, optional: true # kept for legacy/backward compatibility
    has_many :stripe_payment_items, dependent: :destroy

    validates :stripe_payment_id, presence: true, uniqueness: true

    # à verifier
    
    # Callback pour mettre à jour la disponibilité des produits quand le paiement passe à 'paid'
    # Se déclenche après la mise à jour du status vers 'paid'
    # Cela signifie qu'une vente a été effectuée, donc les produits doivent être mis à jour
    after_update :update_produits_availability_if_paid
    
    private
    
    # Met à jour la disponibilité de tous les produits concernés si le paiement est payé
    # Appelé après la mise à jour du status vers 'paid'
    def update_produits_availability_if_paid
      # Si le status vient de passer à 'paid', mettre à jour la disponibilité de tous les produits
      if saved_change_to_status? && status == 'paid'
        stripe_payment_items.each do |item|
          item.produit&.update_today_availability
        end
      end
    end
end