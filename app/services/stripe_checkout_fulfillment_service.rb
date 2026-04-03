# frozen_string_literal: true

# Idempotent fulfillment from a Stripe Checkout Session (paid): persists StripePayment,
# line items from Stripe (not the browser session cart), optional Commande + Articles,
# and queues a confirmation email once.
class StripeCheckoutFulfillmentService
  Result = Struct.new(:payment, :created, keyword_init: true)

  def initialize(stripe_session)
    @session = stripe_session
  end

  def fulfill!
    return Result.new(payment: nil, created: false) if @session.blank?
    return Result.new(payment: nil, created: false) unless @session.payment_status == "paid"

    payment_intent_id = extract_payment_intent_id(@session)
    raise ArgumentError, "Missing payment_intent on paid checkout session" if payment_intent_id.blank?

    payment = nil
    created = false

    StripePayment.transaction do
      existing = StripePayment.lock.find_by(stripe_checkout_session_id: @session.id)
      if existing
        payment = existing
        created = false
      elsif (dup = StripePayment.lock.find_by(stripe_payment_id: payment_intent_id))
        dup.update!(stripe_checkout_session_id: @session.id) if dup.stripe_checkout_session_id.blank?
        payment = dup
        created = false
      else
        email = @session.customer_email.presence || @session.customer_details&.email
        pm_type = @session.payment_method_types&.first

        payment = StripePayment.create!(
          stripe_checkout_session_id: @session.id,
          stripe_payment_id: payment_intent_id,
          amount: @session.amount_total,
          currency: @session.currency,
          status: @session.payment_status,
          payment_method: pm_type,
          charge_id: payment_intent_id,
          customer_email: email,
          frais_livraison_centimes: @session.total_details&.amount_shipping
        )

        build_line_items!(payment)
        StripeEshopCommandeService.new(payment, @session).attach_commande_if_possible!

        created = true
      end
    end

    enqueue_confirmation!(payment) if created && payment

    Result.new(payment: payment, created: created)
  end

  def self.retrieve_session!(session_id)
    Stripe::Checkout::Session.retrieve({
      id: session_id,
      expand: ["line_items.data.price", "total_details"]
    })
  end

  private

  def extract_payment_intent_id(session)
    pi = session.payment_intent
    pi.is_a?(String) ? pi : pi&.id
  end

  def build_line_items!(payment)
    line_data = line_item_records
    if line_data.blank?
      raise ActiveRecord::RecordNotFound, "Stripe session #{@session.id} has no line items"
    end

    # Prefer products from cart metadata to avoid ambiguity when multiple products
    # share the same stripe_price_id (no unique DB constraint). The metadata stores
    # the exact product IDs the customer actually added to their cart.
    cart_product_ids = @session.metadata&.cart_product_ids.to_s
                               .split(",").map(&:to_i).reject(&:zero?)
    cart_products_by_price_id = if cart_product_ids.any?
      Produit.where(id: cart_product_ids).index_by(&:stripe_price_id)
    else
      {}
    end

    line_data.each do |li|
      price = li.price
      price_id = price.is_a?(String) ? price : price&.id
      raise "Stripe line item without price id" if price_id.blank?

      produit = cart_products_by_price_id[price_id] || Produit.find_by(stripe_price_id: price_id)
      raise ActiveRecord::RecordNotFound, "No produit for Stripe price #{price_id}" unless produit

      qty = li.quantity.to_i
      qty = 1 if qty < 1
      unit_cents = if li.amount_total.present? && qty.positive?
                     li.amount_total.to_i / qty
                   else
                     price.is_a?(String) ? nil : price&.unit_amount
                   end

      StripePaymentItem.create!(
        stripe_payment: payment,
        produit: produit,
        quantity: qty,
        unit_amount: unit_cents
      )
    end
  end

  def line_item_records
    if @session.line_items.present? && @session.line_items.data.present?
      return @session.line_items.data
    end

    Stripe::Checkout::Session.retrieve(
      id: @session.id,
      expand: ["line_items.data.price", "total_details"]
    ).line_items.data
  end

  def enqueue_confirmation!(payment)
    return if payment.confirmation_email_sent_at.present?

    queued = false

    if payment.customer_email.present?
      StripePaymentMailer.confirmation(payment).deliver_later
      queued = true
    end

    if ENV["GMAIL_ACCOUNT"].present?
      StripePaymentMailer.notification_admin(payment).deliver_later
      queued = true
    end

    payment.update_column(:confirmation_email_sent_at, Time.current) if queued
  end
end
