# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe "Webhooks::Stripe", type: :request do
  before do
    Rails.configuration.stripe = Rails.configuration.stripe.merge(webhook_secret: "whsec_test_secret")
  end

  describe "POST /webhooks/stripe" do
    it "returns 503 when webhook secret is missing" do
      Rails.configuration.stripe = Rails.configuration.stripe.merge(webhook_secret: nil)
      post "/webhooks/stripe", params: "{}", headers: { "CONTENT_TYPE" => "application/json" }
      expect(response).to have_http_status(:service_unavailable)
    end

    it "returns 400 on invalid signature" do
      post "/webhooks/stripe",
           params: "{}",
           headers: {
             "CONTENT_TYPE" => "application/json",
             "HTTP_STRIPE_SIGNATURE" => "bad"
           }
      expect(response).to have_http_status(:bad_request)
    end

    it "processes checkout.session.completed" do
      session_obj = double("checkout_session_obj", id: "cs_test_webhook_1")
      data_obj = double("event_data", object: session_obj)
      event = double("Stripe::Event", type: "checkout.session.completed", data: data_obj)

      session = OpenStruct.new(
        id: "cs_test_webhook_1",
        payment_status: "paid",
        payment_intent: "pi_test_webhook_1",
        amount_total: 1000,
        currency: "eur",
        payment_method_types: ["card"],
        customer_email: "w@example.com",
        customer_details: nil,
        line_items: OpenStruct.new(data: [])
      )

      allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
      allow(StripeCheckoutFulfillmentService).to receive(:retrieve_session!).with("cs_test_webhook_1").and_return(session)

      svc = instance_double(StripeCheckoutFulfillmentService, fulfill!: StripeCheckoutFulfillmentService::Result.new(payment: nil, created: false))
      expect(StripeCheckoutFulfillmentService).to receive(:new).with(session).and_return(svc)

      post "/webhooks/stripe",
           params: '{"id":"evt_1"}',
           headers: {
             "CONTENT_TYPE" => "application/json",
             "HTTP_STRIPE_SIGNATURE" => "sig"
           }

      expect(response).to have_http_status(:ok)
    end

    it "returns 500 when fulfillment raises an unexpected error" do
      session_obj = double("checkout_session_obj", id: "cs_test_webhook_err")
      data_obj = double("event_data", object: session_obj)
      event = double("Stripe::Event", type: "checkout.session.completed", data: data_obj)

      session = OpenStruct.new(
        id: "cs_test_webhook_err",
        payment_status: "paid",
        payment_intent: "pi_test_webhook_err",
        amount_total: 1000,
        currency: "eur",
        payment_method_types: ["card"],
        customer_email: "err@example.com",
        customer_details: nil,
        line_items: OpenStruct.new(data: [])
      )

      allow(Stripe::Webhook).to receive(:construct_event).and_return(event)
      allow(StripeCheckoutFulfillmentService).to receive(:retrieve_session!).with("cs_test_webhook_err").and_return(session)

      svc = instance_double(StripeCheckoutFulfillmentService)
      allow(svc).to receive(:fulfill!).and_raise(StandardError, "Fulfillment exploded")
      allow(StripeCheckoutFulfillmentService).to receive(:new).with(session).and_return(svc)

      post "/webhooks/stripe",
           params: '{"id":"evt_err"}',
           headers: {
             "CONTENT_TYPE" => "application/json",
             "HTTP_STRIPE_SIGNATURE" => "sig"
           }

      expect(response).to have_http_status(:internal_server_error)
    end

    it "returns 200 and ignores unknown event types" do
      data_obj = double("event_data", object: double("obj"))
      event = double("Stripe::Event", type: "customer.created", data: data_obj)

      allow(Stripe::Webhook).to receive(:construct_event).and_return(event)

      post "/webhooks/stripe",
           params: '{"id":"evt_unknown"}',
           headers: {
             "CONTENT_TYPE" => "application/json",
             "HTTP_STRIPE_SIGNATURE" => "sig"
           }

      expect(response).to have_http_status(:ok)
    end
  end
end
