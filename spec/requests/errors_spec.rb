# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pages d'erreur", type: :request do
  describe "GET /404" do
    it "affiche la page boutique en français" do
      get "/404"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Page introuvable")
      expect(response.body).to include("Retour à la boutique")
      expect(response.body).to include("noindex")
    end
  end

  describe "token mensuration inconnu" do
    it "sert la même page 404, sans révéler l'invitation" do
      get "/fr/m/inconnu123"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Page introuvable")
      expect(response.body).not_to include("invitation")
    end
  end

  describe "locale anglaise" do
    it "reprend la locale du chemin d'origine" do
      get "/en/m/inconnu123"

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Page not found")
      expect(response.body).to include("Back to the boutique")
    end
  end
end
