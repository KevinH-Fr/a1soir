# frozen_string_literal: true

# Annule une commande e-shop côté app : devis (stock), AvoirRemb remboursement.
# Le remboursement bancaire reste manuel dans le Dashboard Stripe.
class EshopCommandeRemboursementService
  Result = Struct.new(:success, :error_key, :already_done, keyword_init: true) do
    def success?
      success
    end
  end

  NATURE_REMBOURSEMENT = "Stripe e-shop"

  def initialize(commande)
    @commande = commande
  end

  def call
    return failure(:not_eshop) unless @commande.eshop?

    stripe_payment = @commande.stripe_payment
    return failure(:no_stripe_payment) if stripe_payment.blank?
    return failure(:stripe_not_paid) unless stripe_payment.status == "paid"

    return Result.new(success: true, already_done: true) if @commande.remboursee_eshop?

    montant = @commande.stripe_payment.amount.to_d / 100
    return failure(:zero_amount) if montant <= 0

    ActiveRecord::Base.transaction do
      @commande.update!(devis: true)
      @commande.avoir_rembs.create!(
        type_avoir_remb: "remboursement",
        montant: montant,
        nature: NATURE_REMBOURSEMENT,
        custom_date: Date.current
      )
    end

    Result.new(success: true, already_done: false)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("EshopCommandeRemboursementService: #{e.message}")
    failure(:record_invalid)
  end

  private

  def failure(error_key)
    Result.new(success: false, error_key: error_key, already_done: false)
  end
end
