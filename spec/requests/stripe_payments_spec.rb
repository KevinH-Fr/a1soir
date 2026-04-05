# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public StripePayments", type: :request do
  # Products are created without stock checks / QR generation side-effects that
  # might slow tests; GenerateQr is a no-op when no asset exists.

  let!(:produit_eshop) do
    Produit.create!(
      nom: "Robe eshop",
      prixvente: 50,
      stripe_price_id: "price_req_001",
      eshop: true,
      today_availability: true,
      quantite: 2,
      poids: 300
    )
  end

  # -------------------------------------------------------------------------
  # check_online_sales guard (existing test, extended with flash text)
  # -------------------------------------------------------------------------

  describe "POST /fr/stripe_payments — OnlineSales gate" do
    it "redirects with flash alert when online sales are disabled" do
      allow(OnlineSales).to receive(:available?).and_return(false)
      post "/fr/stripe_payments"
      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to include("indisponibles")
    end
  end

  # -------------------------------------------------------------------------
  # add_to_cart
  # -------------------------------------------------------------------------

  describe "POST /fr/stripe_payments/add_to_cart/:id" do
    it "adds the product id to session[:cart]" do
      post "/fr/stripe_payments/add_to_cart/#{produit_eshop.id}"
      expect(session[:cart]).to include(produit_eshop.id)
    end

    it "does not duplicate an already-present product in the cart" do
      post "/fr/stripe_payments/add_to_cart/#{produit_eshop.id}"
      post "/fr/stripe_payments/add_to_cart/#{produit_eshop.id}"
      expect(session[:cart].count(produit_eshop.id)).to eq(1)
    end

    it "sets flash notice/success when product is added" do
      post "/fr/stripe_payments/add_to_cart/#{produit_eshop.id}"
      # The controller uses flash.now[:success] for turbo-stream, :notice for html
      expect(flash[:success].presence || flash[:notice].presence).to be_present
    end

    context "when product is not eshop-enabled" do
      let!(:produit_boutique) { Produit.create!(nom: "Boutique only", eshop: false, stripe_price_id: nil) }

      it "does not add product to cart" do
        post "/fr/stripe_payments/add_to_cart/#{produit_boutique.id}"
        expect(session[:cart]).not_to include(produit_boutique.id)
      end

      it "responds with a flash alert" do
        post "/fr/stripe_payments/add_to_cart/#{produit_boutique.id}"
        expect(flash[:alert].presence || flash.now[:alert].presence).to be_present
      end
    end
  end

  # -------------------------------------------------------------------------
  # remove_from_cart
  # -------------------------------------------------------------------------

  describe "DELETE /fr/stripe_payments/remove_from_cart/:id" do
    before { post "/fr/stripe_payments/add_to_cart/#{produit_eshop.id}" }

    it "removes the product id from session[:cart]" do
      delete "/fr/stripe_payments/remove_from_cart/#{produit_eshop.id}"
      expect(session[:cart]).not_to include(produit_eshop.id)
    end

    it "sets a flash info message" do
      delete "/fr/stripe_payments/remove_from_cart/#{produit_eshop.id}"
      expect(flash[:info].presence || flash.now[:info].presence).to be_present
    end
  end

  # -------------------------------------------------------------------------
  # remove_from_cart_go_back_to_cart
  # -------------------------------------------------------------------------

  describe "DELETE /fr/stripe_payments/remove_from_cart_go_back_to_cart/:id" do
    before { post "/fr/stripe_payments/add_to_cart/#{produit_eshop.id}" }

    it "removes the product from cart and redirects to cart" do
      delete "/fr/stripe_payments/remove_from_cart_go_back_to_cart/#{produit_eshop.id}"
      expect(session[:cart]).not_to include(produit_eshop.id)
      expect(response).to redirect_to("/fr/cart")
    end
  end

  # -------------------------------------------------------------------------
  # POST /fr/stripe_payments — pre-checkout gate (ensure_cart_eligible_for_checkout!)
  # -------------------------------------------------------------------------

  describe "POST /fr/stripe_payments — checkout pre-checks" do
    context "when CGV are not accepted" do
      before { post "/fr/stripe_payments/add_to_cart/#{produit_eshop.id}" }

      it "redirects to cart with flash alert" do
        post "/fr/stripe_payments", params: { cgv_accepted: "0" }
        expect(response).to redirect_to("/fr/cart")
        expect(flash[:alert]).to include("conditions générales")
      end
    end

    context "when cart is empty" do
      it "redirects to cart with flash alert" do
        post "/fr/stripe_payments", params: { cgv_accepted: "1" }
        expect(response).to redirect_to("/fr/cart")
        expect(flash[:alert]).to include("panier")
      end
    end

    context "when a product in the cart has today_availability: false (stock exhausted)" do
      let!(:produit_out_of_stock) do
        Produit.create!(
          nom: "Robe épuisée",
          prixvente: 60,
          stripe_price_id: "price_req_oos_001",
          eshop: true,
          today_availability: false,
          quantite: 0
        )
      end

      before { post "/fr/stripe_payments/add_to_cart/#{produit_out_of_stock.id}" }

      it "redirects to cart with a stock-unavailable flash alert" do
        post "/fr/stripe_payments", params: { cgv_accepted: "1" }
        expect(response).to redirect_to("/fr/cart")
        expect(flash[:alert]).to be_present
        expect(flash[:alert]).to include("disponible").or include("panier")
      end
    end

    context "race condition: product was available when added, boutique sells it before checkout" do
      let!(:client)  { Client.create!(nom: "Race Client", propart: "particulier", intitule: Client::INTITULE_OPTIONS.first, mail: "race@test.com") }
      let!(:profile) { Profile.create!(prenom: "Race", nom: "Vendeur") }

      let!(:produit_race) do
        Produit.create!(
          nom: "Robe race condition",
          prixvente: 70,
          stripe_price_id: "price_req_race_001",
          eshop: true,
          today_availability: true,
          quantite: 1
        )
      end

      before do
        # Customer adds product to cart while it is available
        post "/fr/stripe_payments/add_to_cart/#{produit_race.id}"

        # Boutique sells the last unit in the meantime
        commande = Commande.create!(
          client: client, profile: profile,
          nom: "Vente boutique", montant: 70, devis: false,
          type_locvente: "vente", typeevent: Commande::EVENEMENTS_OPTIONS.first
        )
        Article.create!(commande: commande, produit: produit_race, quantite: 1, locvente: "vente", prix: 70, total: 70)

        # Availability is recalculated (simulates the daily job or after_commit)
        produit_race.update_today_availability
        # Reload so the DB reflects today_availability: false
        produit_race.reload
      end

      it "blocks checkout and redirects with a flash alert about unavailability" do
        post "/fr/stripe_payments", params: { cgv_accepted: "1" }
        expect(response).to redirect_to("/fr/cart")
        expect(flash[:alert]).to be_present
      end
    end

    context "when a product is missing stripe_price_id" do
      let!(:produit_no_price) do
        Produit.create!(
          nom: "Sans price id",
          prixvente: 40,
          stripe_price_id: nil,
          eshop: true,
          today_availability: true,
          quantite: 5
        )
      end

      before { post "/fr/stripe_payments/add_to_cart/#{produit_no_price.id}" }

      it "redirects to cart with a flash alert" do
        post "/fr/stripe_payments", params: { cgv_accepted: "1" }
        expect(response).to redirect_to("/fr/cart")
        expect(flash[:alert]).to be_present
      end
    end
  end

  # -------------------------------------------------------------------------
  # GET purchase_error
  # -------------------------------------------------------------------------

  describe "GET /fr/purchase_error" do
    it "redirects to cart with a payment-cancelled flash alert" do
      get "/fr/purchase_error"
      expect(response).to redirect_to("/fr/cart")
      expect(flash[:alert]).to include("annulé").or include("interrompu")
    end
  end

  # -------------------------------------------------------------------------
  # GET purchase_success — without a real Stripe session
  # -------------------------------------------------------------------------

  describe "GET /fr/purchase_success" do
    it "redirects to cart when session_id param is missing" do
      get "/fr/purchase_success"
      expect(response).to redirect_to("/fr/cart")
      expect(flash[:alert]).to be_present
    end

    it "redirects to cart when Stripe raises InvalidRequestError" do
      allow(StripeCheckoutFulfillmentService).to receive(:retrieve_session!)
        .and_raise(Stripe::InvalidRequestError.new("No such session", :session_id))

      get "/fr/purchase_success", params: { session_id: "cs_bad" }
      expect(response).to redirect_to("/fr/cart")
      expect(flash[:alert]).to be_present
    end
  end
end
