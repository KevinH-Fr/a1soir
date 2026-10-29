# frozen_string_literal: true

module AnalyticsHelper
  GA4_BRAND = "Autour D'Un Soir"
  GA4_CURRENCY = "EUR"
  GA4_FORM_EVENTS = %w[request_appointment message_send].freeze
  META_PIXEL_EVENTS = {
    "view_item" => "ViewContent",
    "add_to_cart" => "AddToCart",
    "add_to_wishlist" => "AddToWishlist",
    "begin_checkout" => "InitiateCheckout",
    "purchase" => "Purchase"
  }.freeze
  TIKTOK_PIXEL_EVENTS = {
    "view_item" => "ViewContent",
    "add_to_cart" => "AddToCart",
    "add_to_wishlist" => "AddToWishlist",
    "begin_checkout" => "InitiateCheckout",
    "purchase" => "Purchase"
  }.freeze

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

  def ga4_add_to_wishlist_payload(produit)
    ga4_rescue("add_to_wishlist") do
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

  # Formulaires du site : l'événement est mémorisé au succès, puis rendu
  # une seule fois sur la page de retour (pas de renvoi au rechargement).
  def ga4_remember_form_event(event_name, session)
    return unless GA4_FORM_EVENTS.include?(event_name)

    session[:ga4_pending_form_events] = Array(session[:ga4_pending_form_events]) | [event_name]
  end

  def ga4_consume_form_event(event_name, session)
    pending = Array(session[:ga4_pending_form_events])
    return nil unless pending.include?(event_name)

    remaining = pending - [event_name]
    if remaining.empty?
      session.delete(:ga4_pending_form_events)
    else
      session[:ga4_pending_form_events] = remaining
    end
    event_name
  end

  # Même identifiant que g:id du flux catalogue (produit-123).
  def meta_pixel_track(ga4_event_name, payload)
    event_name = META_PIXEL_EVENTS[ga4_event_name.to_s]
    return nil if event_name.blank? || payload.blank?

    items = Array(payload[:items] || payload["items"])
    contents = items.filter_map { |item| meta_pixel_content(item) }
    return nil if contents.empty?

    meta_payload = {
      content_ids: contents.map { |content| content[:id] },
      content_type: "product",
      contents: contents,
      value: payload[:value] || payload["value"],
      currency: payload[:currency] || payload["currency"] || GA4_CURRENCY
    }
    if contents.one?
      name = items.first[:item_name] || items.first["item_name"]
      meta_payload[:content_name] = name if name.present?
    end
    if %w[InitiateCheckout Purchase].include?(event_name)
      meta_payload[:num_items] = contents.sum { |content| content[:quantity] }
    end

    {
      event_name: event_name,
      payload: meta_payload,
      event_id: (payload[:transaction_id] || payload["transaction_id"]).presence
    }
  end

  # Mêmes événements catalogue que Meta. Depuis mars 2025 TikTok nomme l'achat Purchase
  # (CompletePayment reste accepté, mais converti côté TikTok).
  # content_id reprend g:id du flux catalogue (produit-123).
  def tiktok_pixel_track(ga4_event_name, payload)
    event_name = TIKTOK_PIXEL_EVENTS[ga4_event_name.to_s]
    return nil if event_name.blank? || payload.blank?

    items = Array(payload[:items] || payload["items"])
    contents = items.filter_map { |item| tiktok_pixel_content(item) }
    return nil if contents.empty?

    tiktok_payload = {
      contents: contents,
      content_type: "product",
      value: payload[:value] || payload["value"],
      currency: payload[:currency] || payload["currency"] || GA4_CURRENCY,
      quantity: contents.sum { |content| content[:quantity] }
    }
    if contents.one?
      tiktok_payload[:content_id] = contents.first[:content_id]
      tiktok_payload[:content_name] = contents.first[:content_name] if contents.first[:content_name].present?
      tiktok_payload[:price] = contents.first[:price]
    end

    {
      event_name: event_name,
      payload: tiktok_payload,
      event_id: (payload[:transaction_id] || payload["transaction_id"]).presence
    }
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

  def tiktok_pixel_content(item)
    id = item[:item_id] || item["item_id"]
    return nil if id.blank?

    content = {
      content_id: id,
      content_type: "product",
      quantity: (item[:quantity] || item["quantity"] || 1).to_i,
      price: (item[:price] || item["price"]).to_f
    }
    name = item[:item_name] || item["item_name"]
    content[:content_name] = name if name.present?
    content
  end

  def meta_pixel_content(item)
    id = item[:item_id] || item["item_id"]
    return nil if id.blank?

    {
      id: id,
      quantity: (item[:quantity] || item["quantity"] || 1).to_i,
      item_price: (item[:price] || item["price"]).to_f
    }
  end

  def ga4_item_category(produit)
    produit.categorie_produits.merge(CategorieProduit.not_service).order(:nom).first&.nom
  end
end
