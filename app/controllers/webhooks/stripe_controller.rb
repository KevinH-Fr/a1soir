# frozen_string_literal: true

module Webhooks
  class StripeController < ActionController::API

    def create
      secret = Rails.configuration.stripe[:webhook_secret].to_s
      if secret.blank?
        Rails.logger.error("Webhooks::StripeController: STRIPE_WEBHOOK_SECRET is not set")
        head :service_unavailable
        return
      end

      payload = request.body.read
      sig_header = request.env["HTTP_STRIPE_SIGNATURE"]

      event = Stripe::Webhook.construct_event(
        payload,
        sig_header,
        secret
      )

      case event.type
      when "checkout.session.completed"
        session_obj = event.data.object
        session = StripeCheckoutFulfillmentService.retrieve_session!(session_obj.id)
        StripeCheckoutFulfillmentService.new(session).fulfill!
      end

      head :ok
    rescue JSON::ParserError => e
      Rails.logger.warn("Stripe webhook JSON error: #{e.message}")
      head :bad_request
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.warn("Stripe webhook signature error: #{e.message}")
      head :bad_request
    rescue StandardError => e
      Rails.logger.error("Stripe webhook: #{e.class} #{e.message}")
      head :internal_server_error
    end
  end
end
