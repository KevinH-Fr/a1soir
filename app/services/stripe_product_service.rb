class StripeProductService
  def initialize(produit)
    @produit = produit
  end

  def create_product_and_price
    return if @produit.stripe_product_id.present? && @produit.stripe_price_id.present?

    # Le flux Checkout n'exige que le Price ; le Product sert au libellé côté Stripe.
    # metadata : facultatif mais utile pour retrouver l'enregistrement Produit depuis le Dashboard Stripe.
    # description : optionnelle ; on évite d'envoyer une chaîne vide et on tronque (limite API ~5000 car.).
    product_attrs = {
      name: @produit.nom.to_s,
      metadata: { "produit_id" => @produit.id.to_s }
    }
    product_attrs[:description] = @produit.description.to_s.truncate(4500) if @produit.description.present?

    stripe_product = Stripe::Product.create(product_attrs)

    stripe_price = Stripe::Price.create({
      unit_amount: (@produit.prixvente * 100).to_i,
      currency: "eur",
      product: stripe_product.id
    })

    @produit.update_columns(stripe_product_id: stripe_product.id, stripe_price_id: stripe_price.id)
  end

  def update_product_and_price
    unless @produit.stripe_product_id.present? && @produit.stripe_price_id.present?
      create_product_and_price
      return
    end

    apply_stripe_updates
  rescue Stripe::InvalidRequestError => e
    raise e unless stale_stripe_ids?(e)

    Rails.logger.warn(
      "StripeProductService: IDs Stripe invalides pour Produit ##{@produit.id} — recréation (#{e.code}): #{e.message}"
    )
    @produit.update_columns(stripe_product_id: nil, stripe_price_id: nil)
    @produit.reload
    create_product_and_price
  end

  private

  def stale_stripe_ids?(error)
    error.code == "resource_missing" ||
      error.message.to_s.match?(/No such product|No such price/i)
  end

  def apply_stripe_updates
    update_attrs = { name: @produit.nom.to_s }
    update_attrs[:description] = @produit.description.to_s.truncate(4500) if @produit.description.present?

    Stripe::Product.update(@produit.stripe_product_id, update_attrs)

    return unless @produit.saved_change_to_prixvente?

    Stripe::Price.update(@produit.stripe_price_id, { active: false })

    new_stripe_price = Stripe::Price.create({
      product: @produit.stripe_product_id,
      unit_amount: (@produit.prixvente * 100).to_i,
      currency: "eur"
    })

    @produit.update_column(:stripe_price_id, new_stripe_price.id)
  end
end
