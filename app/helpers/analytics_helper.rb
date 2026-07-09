# frozen_string_literal: true

module AnalyticsHelper
  GA4_BRAND = "Autour D'Un Soir"
  GA4_CURRENCY = "EUR"

  def analytics_consent?
    cookies[:analytics_consent] == "yes"
  end

  def ga4_item_from_produit(produit, quantity: 1, price: nil)
    return nil if produit.blank?

    item = {
      item_id: "produit-#{produit.id}",
      item_name: produit.nom.to_s,
      item_brand: GA4_BRAND,
      price: (price || produit.prixvente.to_f).round(2),
      quantity: quantity
    }
    category = ga4_item_category(produit)
    item[:item_category] = category if category.present?
    item
  end

  def ga4_view_item_payload(produit)
    ga4_rescue("view_item") do
      item = ga4_item_from_produit(produit)
      next nil if item.blank?

      {
        currency: GA4_CURRENCY,
        value: item[:price],
        items: [item]
      }
    end
  end

  def ga4_add_to_cart_payload(produit)
    ga4_rescue("add_to_cart") do
      item = ga4_item_from_produit(produit)
      next nil if item.blank?

      {
        currency: GA4_CURRENCY,
        value: item[:price],
        items: [item]
      }
    end
  end

  def ga4_begin_checkout_payload(cart)
    ga4_rescue("begin_checkout") do
      items = Array(cart).filter_map { |produit| ga4_item_from_produit(produit) }
      next nil if items.empty?

      {
        currency: GA4_CURRENCY,
        value: items.sum { |item| item[:price] * item[:quantity] }.round(2),
        items: items
      }
    end
  end

  def ga4_purchase_payload(payment)
    ga4_rescue("purchase") do
      items = payment.stripe_payment_items.filter_map do |item|
        next if item.produit.blank?

        unit_price = if item.unit_amount.present?
                       item.unit_amount / 100.0
                     else
                       item.produit.prixvente.to_f
                     end
        ga4_item_from_produit(item.produit, quantity: item.quantity || 1, price: unit_price)
      end
      next nil if items.empty?

      {
        transaction_id: payment.commande&.ref_commande.presence || "payment-#{payment.id}",
        currency: (payment.currency.presence || "eur").upcase,
        value: (payment.amount.to_i / 100.0).round(2),
        tax: 0,
        shipping: ((payment.frais_livraison_centimes || 0) / 100.0).round(2),
        items: items
      }
    end
  end

  def ga4_track_purchase_event(payment, session)
    return unless payment.status == "paid"

    tracked_ids = Array(session[:ga4_purchase_tracked_ids]).map(&:to_i)
    return if tracked_ids.include?(payment.id)

    payload = ga4_purchase_payload(payment)
    return if payload.blank?

    session[:ga4_purchase_tracked_ids] = tracked_ids | [payment.id]
    payload
  end

  def ga4_event_turbo_stream(event_name, payload)
    return if payload.blank?

    ga4_rescue("turbo_stream:#{event_name}", payload) do
      turbo_stream.append("ga4-event-sink") do
        render(partial: "public/shared/ga4_event", locals: { event_name: event_name, payload: payload })
      end
    end
  end

  private

  def ga4_rescue(context, payload = nil)
    result = yield
    # Rails.logger.info("[GA4] #{context} #{(payload || result).inspect}")
    result
  rescue StandardError => e
    Rails.logger.warn("[GA4] #{context} skipped: #{e.class} #{e.message}")
    nil
  end

  def ga4_item_category(produit)
    produit.categorie_produits.merge(CategorieProduit.not_service).order(:nom).first&.nom
  end
end
