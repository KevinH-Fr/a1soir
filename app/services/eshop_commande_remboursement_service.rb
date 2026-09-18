# frozen_string_literal: true

# Annule une commande e-shop côté app : devis (stock), AvoirRemb remboursement.
# Le remboursement bancaire reste manuel dans le Dashboard Stripe.
class EshopCommandeRemboursementService
  Result = Struct.new(
    :success,
    :error_key,
    :already_done,
    :montant,
    :item_ids,
    :include_shipping,
    :full_refund,
    keyword_init: true
  ) do
    def success?
      success
    end
  end

  NATURE_REMBOURSEMENT = "Stripe e-shop"

  def initialize(commande)
    @commande = commande
  end

  def call(article: nil, stripe_payment_item_ids: nil, include_shipping: false)
    return failure(:not_eshop) unless @commande.eshop?

    stripe_payment = @commande.stripe_payment
    return failure(:no_stripe_payment) if stripe_payment.blank?
    return failure(:stripe_not_paid) unless stripe_payment.status == "paid"

    return Result.new(success: true, already_done: true) if @commande.remboursee_eshop?

    if article
      refund_line!(article)
    else
      refund_selected_items!(
        Array(stripe_payment_item_ids).reject(&:blank?),
        include_shipping: include_shipping
      )
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("EshopCommandeRemboursementService: #{e.message}")
    failure(:record_invalid)
  end

  private

  def refund_line!(article)
    item = matching_item(article)
    return failure(:no_items) unless item

    last = stripe_items.not_refunded.where.not(id: item.id).none?
    refund_selected_items!([item.id], include_shipping: last)
  end

  def refund_selected_items!(ids, include_shipping: false)
    items = stripe_items.not_refunded.where(id: ids).to_a
    return failure(:no_items) if items.empty? && !include_shipping

    shipping_euros = include_shipping ? shipping_left_euros : 0.to_d
    montant = items.sum { |item| line_amount_raw(item) }
    montant += shipping_euros
    montant = [montant, remaining_euros].min

    return failure(:zero_amount) if montant <= 0 && @commande.avoir_rembs.remb_only.none?

    full_refund = false
    ActiveRecord::Base.transaction do
      now = Time.current
      items.each do |item|
        item.update!(refunded_at: now)
        destroy_articles_for(item)
      end
      create_avoir!(montant) if montant.positive?
      full_refund = stripe_items.not_refunded.reload.none?
      @commande.update!(devis: true) if full_refund
    end

    Result.new(
      success: true,
      already_done: false,
      montant: montant,
      item_ids: items.map(&:id),
      include_shipping: include_shipping && shipping_euros.positive?,
      full_refund: full_refund
    )
  end

  def destroy_articles_for(item)
    @commande.articles.where(produit_id: item.produit_id).find_each(&:destroy!)
  end

  def matching_item(article)
    return if article.produit_id.blank?

    stripe_items.not_refunded.where(produit_id: article.produit_id).order(:id).first
  end

  def stripe_items
    @commande.stripe_payment.stripe_payment_items
  end

  def line_amount_raw(item)
    qty = item.quantity.presence || 1
    (item.unit_amount.to_i * qty.to_i).to_d / 100
  end

  def shipping_left_euros
    unrefunded_products = stripe_items.not_refunded.sum { |item| line_amount_raw(item) }
    leftover = remaining_euros - unrefunded_products
    leftover.positive? ? leftover : 0.to_d
  end

  def remaining_euros
    paid = @commande.stripe_payment.amount.to_d / 100
    already = @commande.avoir_rembs.remb_only.sum(:montant).to_d
    paid - already
  end

  def create_avoir!(montant)
    @commande.avoir_rembs.create!(
      type_avoir_remb: "remboursement",
      montant: montant,
      nature: NATURE_REMBOURSEMENT,
      custom_date: Date.current
    )
  end

  def failure(error_key)
    Result.new(success: false, error_key: error_key, already_done: false)
  end
end
