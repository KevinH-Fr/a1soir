# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public::Pages", type: :request do
  let!(:produit_a) do
    Produit.create!(
      nom: "Robe A",
      prixvente: 50,
      stripe_price_id: "price_pages_001",
      eshop: true,
      today_availability: true,
      quantite: 3
    )
  end

  let!(:produit_b) do
    Produit.create!(
      nom: "Jupe B",
      prixvente: 30,
      stripe_price_id: "price_pages_002",
      eshop: true,
      today_availability: true,
      quantite: 2
    )
  end

  # -------------------------------------------------------------------------
  # GET /fr/cart
  # -------------------------------------------------------------------------

  describe "GET /fr/cart" do
    context "with an empty cart" do
      it "returns 200" do
        get "/fr/cart"
        expect(response).to have_http_status(:ok)
      end
    end

    context "with products in the cart" do
      before do
        post "/fr/stripe_payments/add_to_cart/#{produit_a.id}"
        post "/fr/stripe_payments/add_to_cart/#{produit_b.id}"
      end

      it "returns 200" do
        get "/fr/cart"
        expect(response).to have_http_status(:ok)
      end

      it "assigns @total_amount equal to the sum of prixvente" do
        get "/fr/cart"
        # @total_amount = 50 + 30 = 80
        expect(response.body).to include("80")
      end

      it "shows both product names" do
        get "/fr/cart"
        expect(response.body).to include("Robe A")
        expect(response.body).to include("Jupe B")
      end
    end

    context "with two products of the same type but different taille (variant matrix)" do
      let!(:taille_s) { Taille.create!(nom: "S") }
      let!(:taille_m) { Taille.create!(nom: "M") }

      let!(:produit_s) do
        Produit.create!(
          nom: "Robe variante",
          prixvente: 60,
          poids: 400,
          stripe_price_id: "price_pages_var_s",
          eshop: true,
          today_availability: true,
          quantite: 1,
          taille: taille_s
        )
      end

      let!(:produit_m) do
        Produit.create!(
          nom: "Robe variante",
          prixvente: 60,
          poids: 400,
          stripe_price_id: "price_pages_var_m",
          eshop: true,
          today_availability: true,
          quantite: 1,
          taille: taille_m
        )
      end

      before do
        post "/fr/stripe_payments/add_to_cart/#{produit_s.id}"
        post "/fr/stripe_payments/add_to_cart/#{produit_m.id}"
      end

      it "includes both variants in the cart" do
        get "/fr/cart"
        expect(session[:cart]).to include(produit_s.id)
        expect(session[:cart]).to include(produit_m.id)
      end

      it "sums prixvente across both variants" do
        get "/fr/cart"
        # 60 + 60 = 120
        expect(response.body).to include("120")
      end
    end
  end

  # -------------------------------------------------------------------------
  # POST /fr/cart/transfer_to_cabine
  # -------------------------------------------------------------------------

  describe "POST /fr/cart/transfer_to_cabine" do
    context "when cart has items" do
      before { post "/fr/stripe_payments/add_to_cart/#{produit_a.id}" }

      it "redirects to cabine_essayage path" do
        post "/fr/cart/transfer_to_cabine"
        expect(response).to redirect_to("/fr/cabine_essayage")
      end

      it "moves items from session[:cart] to session[:cabine_cart]" do
        post "/fr/cart/transfer_to_cabine"
        expect(session[:cabine_cart]).to include(produit_a.id)
        expect(session[:cart]).to be_empty
      end

      it "shows a success flash notice" do
        post "/fr/cart/transfer_to_cabine"
        expect(flash[:notice]).to be_present
      end
    end

    context "when cart is empty" do
      it "redirects to cart with a flash alert" do
        post "/fr/cart/transfer_to_cabine"
        expect(response).to redirect_to("/fr/cart")
        expect(flash[:alert]).to be_present
      end
    end

    context "when transfer would exceed 10 items in cabine" do
      before do
        # cabine_add_product only responds to turbo_stream — use the correct
        # Accept header so the session cookie is committed between requests.
        turbo_headers = { "Accept" => "text/vnd.turbo-stream.html, text/html" }

        # Fill cabine_cart with 9 items by adding products one by one
        9.times do |i|
          p = Produit.create!(
            nom: "Produit cabine #{i}",
            stripe_price_id: "price_cab_pre_#{i}",
            eshop: true,
            today_availability: true,
            quantite: 1
          )
          post "/fr/cabine/add_product/#{p.id}", headers: turbo_headers
        end
        # Add 2 items to shop cart; transfer would make 9 + 2 = 11 items
        post "/fr/stripe_payments/add_to_cart/#{produit_a.id}"
        post "/fr/stripe_payments/add_to_cart/#{produit_b.id}"
      end

      it "redirects to cart with a limit-reached flash alert" do
        post "/fr/cart/transfer_to_cabine"
        expect(response).to redirect_to("/fr/cart")
        expect(flash[:alert]).to be_present
      end
    end
  end

  # -------------------------------------------------------------------------
  # POST /fr/cabine/add_product/:id
  # -------------------------------------------------------------------------

  describe "POST /fr/cabine/add_product/:id" do
    it "adds the product to session[:cabine_cart]" do
      post "/fr/cabine/add_product/#{produit_a.id}"
      expect(session[:cabine_cart]).to include(produit_a.id)
    end

    it "does not duplicate a product already in the cabine cart" do
      post "/fr/cabine/add_product/#{produit_a.id}"
      post "/fr/cabine/add_product/#{produit_a.id}"
      expect(session[:cabine_cart].count(produit_a.id)).to eq(1)
    end

    context "when cabine cart already has 10 items" do
      before do
        # cabine_add_product only responds to turbo_stream — use the correct
        # Accept header so the session cookie is committed between requests.
        turbo_headers = { "Accept" => "text/vnd.turbo-stream.html, text/html" }
        10.times do |i|
          p = Produit.create!(
            nom: "Cabine full #{i}",
            stripe_price_id: "price_cab_full_#{i}",
            eshop: true,
            today_availability: true,
            quantite: 1
          )
          post "/fr/cabine/add_product/#{p.id}", headers: turbo_headers
        end
      end

      it "does not add an 11th product" do
        post "/fr/cabine/add_product/#{produit_b.id}"
        expect(session[:cabine_cart]).not_to include(produit_b.id)
      end

      it "returns a limit-reached flash alert" do
        post "/fr/cabine/add_product/#{produit_b.id}"
        expect(flash[:alert].presence || flash.now[:alert].presence).to be_present
      end
    end
  end

  # -------------------------------------------------------------------------
  # DELETE /fr/cabine/remove_product/:id
  # -------------------------------------------------------------------------

  describe "DELETE /fr/cabine/remove_product/:id" do
    before { post "/fr/cabine/add_product/#{produit_a.id}" }

    it "removes the product from session[:cabine_cart]" do
      delete "/fr/cabine/remove_product/#{produit_a.id}"
      expect(session[:cabine_cart]).not_to include(produit_a.id)
    end

    it "sets an info flash message" do
      delete "/fr/cabine/remove_product/#{produit_a.id}"
      expect(flash[:info].presence || flash.now[:info].presence).to be_present
    end
  end
end
