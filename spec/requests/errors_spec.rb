# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pages d'erreur", type: :request do
  describe "GET /404" do
    it "affiche la page boutique en français" do
      # GET /404 passe par public/404.html (200) via le serveur de fichiers.
      # exceptions_app appelle le routeur directement.
      status, _headers, body = Rails.application.routes.call(
        Rack::MockRequest.env_for("/404", "HTTP_HOST" => "www.example.com")
      )
      html = body.each.to_a.join

      expect(status).to eq(404)
      expect(html).to include("Page introuvable")
      expect(html).to include("Retour à la boutique")
      expect(html).to include("noindex")
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
