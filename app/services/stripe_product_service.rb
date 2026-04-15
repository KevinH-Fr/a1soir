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
    product_attrs[:images] = stripe_product_images if stripe_product_images.any?

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

  def archive_product_and_price
    return unless @produit.stripe_price_id.present?

    Stripe::Price.update(@produit.stripe_price_id, { active: false })
    return unless @produit.stripe_product_id.present?

    Stripe::Product.update(@produit.stripe_product_id, { active: false })
  rescue Stripe::InvalidRequestError => e
    Rails.logger.warn(
      "StripeProductService: archive impossible pour Produit ##{@produit.id} (#{e.code}): #{e.message}"
    )
  end

  private

  def stale_stripe_ids?(error)
    error.code == "resource_missing" ||
      error.message.to_s.match?(/No such product|No such price/i)
  end

  def apply_stripe_updates
    update_attrs = { name: @produit.nom.to_s }
    update_attrs[:description] = @produit.description.to_s.truncate(4500) if @produit.description.present?
    update_attrs[:images] = stripe_product_images

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

  def stripe_product_images
    image_url = stripe_primary_image_url
    return [image_url] if image_url.present?

    []
  end

  def stripe_primary_image_url
    return unless @produit.image1.attached?

    normalized_https_url(@produit.image1.url)
  rescue StandardError => e
    Rails.logger.warn(
      "StripeProductService: impossible de générer l'image pour Produit ##{@produit.id} (#{e.class}): #{e.message}"
    )
    nil
  end

  def normalized_https_url(value)
    raw = value.to_s.strip
    return if raw.blank?

    uri = URI.parse(raw)
    return raw if uri.is_a?(URI::HTTPS) && uri.host.present?
  rescue URI::InvalidURIError
    nil
  end
end
