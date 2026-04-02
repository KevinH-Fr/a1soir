# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public StripePayments", type: :request do
  describe "POST /fr/stripe_payments" do
    it "redirects when online sales are disabled" do
      allow(OnlineSales).to receive(:available?).and_return(false)
      post "/fr/stripe_payments"
      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to be_present
    end
  end
end
