# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe StripeEshopCommandeService do
  let!(:profile) { Profile.create!(prenom: "Vendeur", nom: "Eshop") }

  let!(:es_example_uid) { SecureRandom.hex(8) }
  let(:es_checkout_session_id) { "cs_es_#{es_example_uid}" }
  let(:es_payment_intent_id) { "pi_es_#{es_example_uid}" }
  let(:checkout_customer_email) { "svc-#{SecureRandom.hex(6)}@example.com" }

  let!(:produit) do
    Produit.create!(
      nom: "Robe commande svc",
      prixvente: 60,
      stripe_price_id: "price_svc_#{SecureRandom.hex(8)}",
      eshop: true,
      today_availability: true,
      quantite: 2
    )
  end

  let!(:payment) do
    StripePayment.create!(
      stripe_payment_id: es_payment_intent_id,
      stripe_checkout_session_id: es_checkout_session_id,
      amount: 6000,
      currency: "eur",
      status: "paid",
      customer_email: checkout_customer_email
    )
  end

  let!(:payment_item) do
    StripePaymentItem.create!(
      stripe_payment: payment,
      produit: produit,
      quantity: 1,
      unit_amount: 6000
    )
  end

  let(:mock_session) { OpenStruct.new(id: es_checkout_session_id) }

  subject(:service) { described_class.new(payment, mock_session) }

  # -------------------------------------------------------------------------
  # attach_commande_if_possible!
  # -------------------------------------------------------------------------

  describe "#attach_commande_if_possible!" do
    it "creates a Commande linked to the payment" do
      expect { service.attach_commande_if_possible! }.to change(Commande, :count).by(1)
      expect(payment.reload.commande).to be_a(Commande)
    end

    it "creates an Article with locvente: 'vente' for each line item" do
      expect { service.attach_commande_if_possible! }.to change(Article, :count).by(1)
      article = Article.last
      expect(article.locvente).to eq("vente")
      expect(article.produit).to eq(produit)
    end

    it "sets the Commande as an eshop order" do
      service.attach_commande_if_possible!
      expect(payment.reload.commande.eshop).to be(true)
    end

    it "sets type_locvente to 'vente' on the Commande" do
      service.attach_commande_if_possible!
      expect(payment.reload.commande.type_locvente).to eq("vente")
    end

    it "creates a Client when no shipping name (placeholder prenom/nom)" do
      expect { service.attach_commande_if_possible! }.to change(Client, :count).by(1)
      client = payment.reload.commande.client
      expect(client.mail).to eq(checkout_customer_email)
      expect(client.prenom).to eq("Client")
      expect(client.nom).to eq("E Shop")
    end

    it "reuses an existing Client when normalized mail and family name match (case-insensitive)" do
      Client.create!(prenom: "Jean", nom: "E-shop", mail: checkout_customer_email,
                     propart: "particulier", intitule: Client::INTITULE_OPTIONS.first)
      expect { service.attach_commande_if_possible! }.not_to change(Client, :count)
      expect(payment.reload.commande.client.nom).to eq("E Shop")
    end

    it "reuses when checkout email casing differs from stored mail" do
      Client.create!(prenom: "Jean", nom: "E-shop", mail: checkout_customer_email,
                     propart: "particulier", intitule: Client::INTITULE_OPTIONS.first)
      payment.update_column(:customer_email, checkout_customer_email.upcase)
      expect { service.attach_commande_if_possible! }.not_to change(Client, :count)
    end

    it "creates a new Client when mail matches but family name does not" do
      Client.create!(prenom: "Paul", nom: "Martin", mail: checkout_customer_email,
                     propart: "particulier", intitule: Client::INTITULE_OPTIONS.first)
      expect { service.attach_commande_if_possible! }.to change(Client, :count).by(1)
      expect(Client.where(mail: checkout_customer_email).count).to eq(2)
      expect(payment.reload.commande.client.nom).to eq("E Shop")
    end

    context "when the checkout session includes shipping" do
      let(:mock_addr) do
        OpenStruct.new(
          line1: "8 avenue des Tests",
          line2: nil,
          city: "Bordeaux",
          postal_code: "33000",
          country: "FR"
        )
      end
      let(:mock_shipping) { OpenStruct.new(name: "Sophie Livraison", address: mock_addr) }
      let(:mock_session) do
        OpenStruct.new(
          id: es_checkout_session_id,
          shipping_details: mock_shipping,
          customer_details: OpenStruct.new(phone: "+33611112222")
        )
      end

      before do
        payment.update!(StripeCheckoutShippingMapper.stripe_payment_shipping_attrs(mock_session))
      end

      it "creates the Client with address and name from shipping" do
        service.attach_commande_if_possible!
        client = Client.find_by(mail: checkout_customer_email)
        expect(client.prenom).to eq("Sophie")
        expect(client.nom).to eq("Livraison")
        expect(client.adresse).to eq("8 avenue des Tests")
        expect(client.cp).to eq("33000")
        expect(client.ville).to eq("Bordeaux")
        expect(client.pays).to eq("FR")
        expect(client.tel).to eq("+33611112222")
      end

      it "includes a Livraison line in commande commentaires" do
        service.attach_commande_if_possible!
        expect(payment.reload.commande.commentaires).to include("Livraison:")
        expect(payment.commande.commentaires).to include("Sophie Livraison")
        expect(payment.commande.commentaires).to include("Bordeaux")
      end

      it "does not overwrite an existing matched Client address or phone from Stripe" do
        existing = Client.create!(
          prenom: "Sophie",
          nom: "Livraison",
          mail: checkout_customer_email,
          adresse: "1 rue Ancienne",
          cp: "06000",
          ville: "Nice",
          pays: "FR",
          tel: "+33600000001",
          propart: "particulier",
          intitule: Client::INTITULE_OPTIONS.first
        )
        service.attach_commande_if_possible!
        existing.reload
        expect(existing.adresse).to eq("1 rue Ancienne")
        expect(existing.cp).to eq("06000")
        expect(existing.ville).to eq("Nice")
        expect(existing.tel).to eq("+33600000001")
        expect(payment.reload.commande.client_id).to eq(existing.id)
        expect(payment.shipping_address_line1).to eq("8 avenue des Tests")
        expect(payment.commande.commentaires).to include("8 avenue des Tests")
      end
    end

    it "is idempotent when called twice on the same payment" do
      service.attach_commande_if_possible!
      expect { service.attach_commande_if_possible! }.not_to change(Commande, :count)
    end

    context "when payment already has a commande_id" do
      before do
        service.attach_commande_if_possible!
      end

      it "does not create a second Commande" do
        expect { service.attach_commande_if_possible! }.not_to change(Commande, :count)
      end
    end

    context "when customer email is blank" do
      before { payment.update_column(:customer_email, nil) }

      it "does not create a Commande" do
        expect { service.attach_commande_if_possible! }.not_to change(Commande, :count)
      end
    end

    context "when no Profile exists" do
      before do
        allow(Profile).to receive(:order).with(:id).and_return(Profile.where("1 = 0"))
      end

      it "does not create a Commande" do
        expect { service.attach_commande_if_possible! }.not_to change(Commande, :count)
      end
    end

    context "with multiple line items (two different products)" do
      let!(:produit2) do
        Produit.create!(
          nom: "Jupe commande svc",
          prixvente: 40,
          stripe_price_id: "price_svc2_#{SecureRandom.hex(8)}",
          eshop: true,
          today_availability: true,
          quantite: 1
        )
      end

      before do
        StripePaymentItem.create!(
          stripe_payment: payment,
          produit: produit2,
          quantity: 1,
          unit_amount: 4000
        )
      end

      it "creates one Article per line item" do
        expect { service.attach_commande_if_possible! }.to change(Article, :count).by(2)
      end

      it "attaches all articles to the same Commande" do
        service.attach_commande_if_possible!
        commande = payment.reload.commande
        expect(commande.articles.count).to eq(2)
      end
    end
  end

  # -------------------------------------------------------------------------
  # Stock race condition
  #
  # The eshop stock gate is at checkout (ensure_cart_eligible_for_checkout!).
  # The fulfillment service (running inside the Stripe webhook) does NOT
  # re-check availability — it always persists the line items. This means
  # that if the last unit is sold in-store between checkout and webhook
  # processing, statut_disponibilite will show disponibles < 0 after the
  # webhook runs. The after_commit callback then sets today_availability:
  # false so no further purchases are possible.
  # -------------------------------------------------------------------------

  describe "stock race condition: boutique sells last unit before webhook fires" do
    let!(:race_uid) { SecureRandom.hex(8) }
    let(:race_checkout_session_id) { "cs_race_#{race_uid}" }
    let(:race_payment_intent_id) { "pi_race_#{race_uid}" }
    let(:mock_session_race) { OpenStruct.new(id: race_checkout_session_id) }

    let!(:client_boutique) do
      Client.create!(
        nom: "Boutique Client",
        propart: "particulier",
        intitule: Client::INTITULE_OPTIONS.first,
        mail: "boutique@example.com"
      )
    end

    let!(:produit_race) do
      Produit.create!(
        nom: "Robe race svc",
        prixvente: 60,
        stripe_price_id: "price_race_#{SecureRandom.hex(8)}",
        eshop: true,
        today_availability: true,
        quantite: 1
      )
    end

    let!(:payment_race) do
      StripePayment.create!(
        stripe_payment_id: race_payment_intent_id,
        stripe_checkout_session_id: race_checkout_session_id,
        amount: 6000,
        currency: "eur",
        status: "paid",
        customer_email: "race@example.com"
      )
    end

    before do
      # Eshop checkout has already passed the availability gate.
      # The Stripe webhook creates the StripePaymentItem…
      StripePaymentItem.create!(stripe_payment: payment_race, produit: produit_race, quantity: 1, unit_amount: 6000)

      # …but in the meantime, the boutique has sold the same last unit.
      commande_boutique = Commande.create!(
        client: client_boutique,
        profile: profile,
        nom: "Vente boutique",
        montant: 60,
        devis: false,
        type_locvente: "vente",
        typeevent: Commande::EVENEMENTS_OPTIONS.first
      )
      Article.create!(
        commande: commande_boutique,
        produit: produit_race,
        quantite: 1,
        locvente: "vente",
        prix: 60,
        total: 60
      )
    end

    it "fulfillment still creates the Commande (gate is at checkout, not at webhook)" do
      svc = described_class.new(payment_race, mock_session_race)
      expect { svc.attach_commande_if_possible! }.to change(Commande, :count).by(1)
    end

    it "statut_disponibilite shows disponibles = -1 after both sales" do
      # 1 initial − 1 boutique − 1 eshop = -1
      result = produit_race.statut_disponibilite(Time.current, Time.current)
      expect(result[:disponibles]).to eq(-1)
    end

    it "update_today_availability sets today_availability to false after the race" do
      produit_race.update_today_availability
      expect(produit_race.reload.today_availability).to be(false)
    end
  end
end
