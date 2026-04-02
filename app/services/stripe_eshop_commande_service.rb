# frozen_string_literal: true

# Builds an admin Commande + vente Articles from a fulfilled StripePayment when possible.
class StripeEshopCommandeService
  def initialize(stripe_payment, stripe_session = nil)
    @payment = stripe_payment
    @session = stripe_session
  end

  def attach_commande_if_possible!
    return if @payment.commande_id.present?
    return if @payment.stripe_payment_items.blank?

    profile = Profile.order(:id).first
    unless profile
      Rails.logger.warn("StripeEshopCommandeService: no Profile — skip Commande for StripePayment #{@payment.id}")
      return
    end

    email = @payment.customer_email.presence
    unless email
      Rails.logger.warn("StripeEshopCommandeService: no customer email — skip Commande for StripePayment #{@payment.id}")
      return
    end

    client = find_or_create_eshop_client!(email)

    commande = Commande.create!(
      client: client,
      profile: profile,
      nom: "E-shop Stripe",
      montant: (@payment.amount.to_d / 100),
      description: "Vente en ligne (Stripe)",
      commentaires: commande_comment,
      devis: false,
      type_locvente: "vente",
      typeevent: Commande::EVENEMENTS_OPTIONS.first
    )

    @payment.stripe_payment_items.each do |item|
      next unless item.produit_id

      qty = item.quantity.presence || 1
      unit_eur = item.unit_amount.present? ? (item.unit_amount.to_d / 100) : item.produit.prixvente
      line_total = unit_eur * qty

      Article.create!(
        commande: commande,
        produit_id: item.produit_id,
        quantite: qty,
        prix: unit_eur,
        total: line_total,
        locvente: "vente"
      )
    end

    @payment.update!(commande: commande)
  end

  private

  def commande_comment
    parts = []
    parts << "Stripe PaymentIntent: #{@payment.stripe_payment_id}" if @payment.stripe_payment_id.present?
    parts << "Session: #{@session.id}" if @session.respond_to?(:id) && @session.id.present?
    parts.join(" — ")
  end

  def find_or_create_eshop_client!(email)
    existing = Client.find_by(mail: email)
    return existing if existing

    Client.create!(
      prenom: "Client",
      nom: "E-shop",
      mail: email,
      propart: "particulier",
      intitule: Client::INTITULE_OPTIONS.first
    )
  end
end
