class StripePaymentItem < ApplicationRecord
    belongs_to :stripe_payment
    belongs_to :produit
    
    # à verifier

    # Callback pour mettre à jour la disponibilité du produit quand un paiement est créé
    # Se déclenche après la création d'un StripePaymentItem
    # La disponibilité sera mise à jour si le paiement est déjà payé ou quand il le devient
    after_commit :update_produit_availability_if_paid, on: [:create]
    
    private
    
    # Met à jour la disponibilité du produit si le paiement est payé
    # Appelé après la création d'un StripePaymentItem
    def update_produit_availability_if_paid
      # Si le paiement est payé, mettre à jour la disponibilité du produit
      # car cela signifie qu'une vente a été effectuée (affecte le stock)
      if stripe_payment&.status == 'paid'
        produit&.update_today_availability
      end
    end
end