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

    profile = Profile.for_eshop_commandes

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
      typeevent: "divers",
      eshop: true
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
    ship = StripeCheckoutShippingMapper.commande_shipping_comment(@payment)
    parts << ship if ship.present?
    parts.join(" — ")
  end

  def find_or_create_eshop_client!(email)
    addr_attrs = StripeCheckoutShippingMapper.client_address_attrs(@session, @payment)
    name_prenom, name_nom = StripeCheckoutShippingMapper.name_parts_from_shipping_name(
      StripeCheckoutShippingMapper.shipping_recipient_name(@session, @payment)
    )

    existing = Client.find_existing_for_public_contact(
      email: email,
      nom: name_nom,
      prenom: name_prenom,
      use_prenom_nom_fallback: false
    )
    return existing if existing

    Client.create!(
      {
        prenom: name_prenom,
        nom: name_nom,
        mail: email,
        propart: "particulier",
        intitule: Client::ESHOP_DEFAULT_INTITULE
      }.merge(addr_attrs)
    )
  end
end
