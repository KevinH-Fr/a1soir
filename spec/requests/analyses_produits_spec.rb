require 'rails_helper'

RSpec.describe "AnalysesProduits", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/analyses_produits/index"
      expect(response).to have_http_status(:success)
    end
  end

end
