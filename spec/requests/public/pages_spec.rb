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

    context "when product has today_availability: false" do
      let!(:produit_indispo) do
        Produit.create!(
          nom: "Robe indispo cabine",
          stripe_price_id: "price_cab_oos_001",
          eshop: true,
          today_availability: false,
          quantite: 0
        )
      end

      it "does not add product to cabine cart" do
        post "/fr/cabine/add_product/#{produit_indispo.id}"
        expect(session[:cabine_cart]).not_to include(produit_indispo.id)
      end

      it "returns a flash alert" do
        post "/fr/cabine/add_product/#{produit_indispo.id}"
        expect(flash[:alert].presence || flash.now[:alert].presence).to be_present
      end
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

  # -------------------------------------------------------------------------
  # GET /fr/produit/:slug-:id — canonical / og:url (no back_url in meta)
  # -------------------------------------------------------------------------

  describe "GET /fr/produit/:slug-:id" do
    let!(:produit_seo) do
      Produit.create!(
        nom: "Robe SEO",
        handle: "robe-seo",
        prixvente: 50,
        stripe_price_id: "price_seo_001",
        eshop: true,
        today_availability: true,
        quantite: 1,
        actif: true
      )
    end

    let(:canonical_url) { "http://www.example.com/fr/produit/robe-seo-#{produit_seo.id}" }

    it "renders a clean canonical without back_url query param" do
      get "/fr/produit/robe-seo-#{produit_seo.id}", params: { back_url: "/fr/produits" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(<link rel="canonical" href="#{canonical_url}">))
      expect(response.body).not_to include("back_url")
    end

    it "renders clean og:url without query params" do
      get "/fr/produit/robe-seo-#{produit_seo.id}", params: { back_url: "/fr/produits" }

      expect(response.body).to include(%(property="og:url" content="#{canonical_url}"))
    end

    it "renders product-specific title and meta description" do
      get "/fr/produit/robe-seo-#{produit_seo.id}"

      expect(response.body).to include("<title>Robe SEO | Autour D&#39;Un Soir</title>")
      expect(response.body).to include('meta name="description" content=')
      expect(response.body).to include("Robe SEO")
    end

    it "renders absolute Cloudinary URL for og:image and twitter:image" do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new("fake"),
        filename: "robe-seo.jpg",
        content_type: "image/jpeg"
      )
      produit_seo.image1.attach(blob)

      get "/fr/produit/robe-seo-#{produit_seo.id}"

      og_url = "https://res.cloudinary.com/dukne3lhz/image/upload/q_auto,f_auto,w_1200/#{blob.key}"
      expect(response.body).to include(%(property="og:image" content="#{og_url}"))
      expect(response.body).to include(%(name="twitter:image" content="#{og_url}"))
      expect(response.body).not_to include('property="og:image" content="/images/')
    end
  end

  # -------------------------------------------------------------------------
  # GET /fr/produits — back_url avec filtres + recherche
  # -------------------------------------------------------------------------

  describe "GET /fr/produits" do
    let!(:taille_m) { Taille.create!(nom: "M") }
    let!(:produit_listing) do
      Produit.create!(
        nom: "Robe listing back",
        handle: "robe-listing-back",
        prixvente: 50,
        stripe_price_id: "price_listing_back",
        eshop: true,
        today_availability: true,
        quantite: 1,
        taille: taille_m,
        actif: true
      )
    end

    let(:search_q) do
      {
        nom_or_description_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_cont: "Robe"
      }
    end

    def extract_back_url_from_response
      href = response.body[/href="([^"]*back_url=[^"]*)"/, 1]
      return if href.blank?

      CGI.unescape(CGI.parse(URI.parse(href).query)["back_url"].first)
    end

    it "includes active filters and search term in product back_url" do
      get "/fr/produits", params: { taille: taille_m.id, q: search_q }

      expect(response).to have_http_status(:ok)

      back_url = extract_back_url_from_response
      expect(back_url).to include("taille=#{taille_m.id}")
      expect(back_url).to include("Robe")
    end

    it "preserves search when updating a filter via turbo stream" do
      post "/fr/update_filters",
           params: { taille: taille_m.id, q: search_q },
           headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Robe")
      expect(response.body).to include("taille=#{taille_m.id}")
    end

    it "links clear all filters to a clean produits URL" do
      get "/fr/produits", params: { taille: taille_m.id, q: search_q }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('href="/fr/produits"')
      expect(response.body).not_to include("update_filters")
    end

    it "refreshes filter dropdowns when search changes via turbo stream" do
      get "/fr/produits",
          params: { q: search_q },
          headers: { "Accept" => "text/vnd.turbo-stream.html, text/html" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('<turbo-stream action="update" target="filtres-taille"')
      expect(response.body).to include('<turbo-stream action="update" target="produits-filtres"')
      expect(response.body).not_to include('<turbo-stream action="update" target="produits-search"')
    end
  end

  # -------------------------------------------------------------------------
  # GET /fr/categories
  # -------------------------------------------------------------------------

  describe "GET /fr/categories" do
    let!(:categorie) do
      CategorieProduit.create!(nom: "robes test", texte_annonce: "Robes pour votre jour J")
    end

    it "returns 200 and lists categories" do
      get "/fr/categories"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Robes Test")
      expect(response.body).to include("Robes pour votre jour J")
      expect(response.body).to include("collection-card")
    end
  end

  # -------------------------------------------------------------------------
  # GET /fr/faq — FAQPage schema
  # -------------------------------------------------------------------------

  describe "GET /fr/faq" do
    it "includes FAQPage structured data" do
      get "/fr/faq"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('"@type":"FAQPage"')
    end
  end
end
