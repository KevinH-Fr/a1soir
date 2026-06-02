# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public::SeoPages", type: :request do
  describe "GET /fr/robe-de-mariee-cannes" do
    before do
      CategorieProduit.find_or_create_by!(nom: "robes de mariée courtes")
      CategorieProduit.find_or_create_by!(nom: "robes de mariée longues")
    end

    it "returns 200 with meta title and breadcrumb schema" do
      get "/fr/robe-de-mariee-cannes"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Robe de mariée à Cannes")
      expect(response.body).not_to include("page-header-container")
      expect(response.body).to include("Nice")
      expect(response.body).to include("Robes De Mariée Courtes")
      expect(response.body).to include("Combien de temps avant le mariage")
      expect(response.body).to include("Robe de mariée Cannes - Autour D")
      expect(response.body).to include("BreadcrumbList")
      expect(response.body).to include("FAQPage")
    end
  end

  describe "GET /fr/essayage-robe-de-mariee-cannes" do
    it "returns 200 without missing translations" do
      get "/fr/essayage-robe-de-mariee-cannes"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("translation missing")
      expect(response.body).to include("Essayage robe de mariée à Cannes")
    end
  end

  describe "GET /fr/guides/comment-choisir-sa-robe-de-mariee" do
    before do
      CategorieProduit.find_or_create_by!(nom: "robes de mariée courtes")
      CategorieProduit.find_or_create_by!(nom: "robes de mariée longues")
    end

    it "returns 200 with guide content" do
      get "/fr/guides/comment-choisir-sa-robe-de-mariee"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Comment choisir sa robe de mariée")
      expect(response.body).not_to include("page-header-container")
      expect(response.body).to include("seo-section-image")
      expect(response.body).to include("Robes De Mariée Courtes")
      expect(response.body).to include("Robes De Mariée Longues")
    end

    it "returns 200 in English" do
      get "/en/guides/comment-choisir-sa-robe-de-mariee"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("How to choose your wedding dress")
    end
  end

  describe "GET /fr/guides" do
    it "returns 200 with hub links" do
      get "/fr/guides"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Guides &amp; conseils")
      expect(response.body).to include("seo-hub-card")
      expect(response.body).to include("Lire le guide")
      expect(response.body).to include("robe-de-mariee-cannes")
      expect(response.body).to include("tenue-gala-ceremonie")
      expect(response.body).to include("location-smoking-costume-cannes")
    end
  end

  describe "GET /fr/guides/tenue-gala-ceremonie" do
    it "returns 200 with event guide content" do
      get "/fr/guides/tenue-gala-ceremonie"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("translation missing")
      expect(response.body).to include("Tenue de gala et cérémonie")
    end
  end

  describe "GET /fr/guides/location-smoking-costume-cannes" do
    it "returns 200 with service guide content" do
      get "/fr/guides/location-smoking-costume-cannes"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("translation missing")
      expect(response.body).to include("Location smoking et costume à Cannes")
    end
  end

  describe "GET /fr/guides/chaussures-accessoires-soiree" do
    before do
      CategorieProduit.find_or_create_by!(nom: "chaussures")
      CategorieProduit.find_or_create_by!(nom: "accessoires")
      CategorieProduit.find_or_create_by!(nom: "accessoires femmes")
    end

    it "returns 200 with shoes and accessories guide content" do
      get "/fr/guides/chaussures-accessoires-soiree"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("translation missing")
      expect(response.body).to include("Chaussures et accessoires de soirée")
      expect(response.body).to include("Chaussures")
      expect(response.body).to include("Accessoires")
      expect(response.body).not_to include("Robes Courtes")
      expect(response.body).not_to include("Robes Longues")
    end
  end

  describe "GET /fr/tenue-festival-de-cannes" do
    it "redirects to festival-de-cannes" do
      get "/fr/tenue-festival-de-cannes"

      expect(response).to redirect_to("/fr/festival-de-cannes")
    end
  end

  describe "unknown local slug" do
    it "returns 404" do
      get "/fr/slug-inconnu"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /en/guides/costume-mariage-cannes" do
    it "redirects to the local landing page" do
      get "/en/guides/costume-mariage-cannes"

      expect(response).to redirect_to("/en/costume-mariage-cannes")
    end
  end

  describe "GET /fr/location-smoking-costume-cannes" do
    it "redirects to the guides URL" do
      get "/fr/location-smoking-costume-cannes"

      expect(response).to redirect_to("/fr/guides/location-smoking-costume-cannes")
    end
  end
end
