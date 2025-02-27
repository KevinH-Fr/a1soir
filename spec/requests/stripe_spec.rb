require 'rails_helper'

RSpec.describe "Stripes", type: :request do
  describe "GET /purchase_success" do
    it "returns http success" do
      get "/stripe/purchase_success"
      expect(response).to have_http_status(:success)
    end
  end

end
