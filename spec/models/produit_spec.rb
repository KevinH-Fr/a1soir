# spec/models/produit_spec.rb
require "rails_helper"

RSpec.describe Produit do
  describe "after_create callback" do
    it "calls generate_qr after the model is created" do
      produit = Produit.new(nom: "Test Product", reffrs: "REF123")
      expect(produit).to receive(:generate_qr)
      produit.save
    end
  end

  describe "#generate_qr" do
    it "calls the GenerateQr service with the model" do
      produit = Produit.new(nom: "Test Product", reffrs: "REF123")
      allow(GenerateQr).to receive(:call)
      produit.generate_qr
      expect(GenerateQr).to have_received(:call).with(produit)
    end
  end

  describe "#set_default_poids (after_initialize)" do
    it "sets poids to 2000 when nil on initialize" do
      produit = Produit.new(nom: "Test")
      expect(produit.poids).to eq(2000)
    end

    it "preserves an explicitly set poids" do
      produit = Produit.new(nom: "Test", poids: 500)
      expect(produit.poids).to eq(500)
    end
  end

  describe "#statut_disponibilite" do
    let(:today) { Time.current }

    let!(:client) { Client.create!(nom: "Client Test", propart: "particulier", intitule: Client::INTITULE_OPTIONS.first, mail: "client@test.com") }
    let!(:profile) { Profile.create!(prenom: "Vendeur", nom: "Test") }
    let!(:produit) { Produit.create!(nom: "Robe disponibilite", quantite: 3) }

    def build_boutique_commande
      Commande.create!(
        client: client,
        profile: profile,
        nom: "Commande test",
        montant: 100,
        devis: false,
        type_locvente: "vente",
        typeevent: Commande::EVENEMENTS_OPTIONS.first
      )
    end

    context "with no sales at all" do
      it "returns initial stock as disponibles" do
        result = produit.statut_disponibilite(today, today)
        expect(result[:initial]).to eq(3)
        expect(result[:vendus]).to eq(0)
        expect(result[:disponibles]).to eq(3)
        expect(result[:statut]).to eq("disponible")
      end
    end

    context "with boutique (in-store) sales" do
      it "deducts boutique vente articles from disponibles" do
        commande = build_boutique_commande
        Article.create!(commande: commande, produit: produit, quantite: 2, locvente: "vente", prix: 50, total: 100)

        result = produit.statut_disponibilite(today, today)
        expect(result[:vendus]).to eq(2)
        expect(result[:disponibles]).to eq(1)
        expect(result[:statut]).to eq("disponible")
      end

      it "marks as indisponible when boutique sales exhaust all stock" do
        commande = build_boutique_commande
        Article.create!(commande: commande, produit: produit, quantite: 3, locvente: "vente", prix: 50, total: 150)

        result = produit.statut_disponibilite(today, today)
        expect(result[:disponibles]).to eq(0)
        expect(result[:statut]).to eq("indisponible")
      end

      it "does not count location articles as sales" do
        commande = build_boutique_commande
        Article.create!(commande: commande, produit: produit, quantite: 2, locvente: "location", prix: 50, total: 100)

        result = produit.statut_disponibilite(today, today)
        expect(result[:vendus]).to eq(0)
        expect(result[:disponibles]).to eq(3)
      end
    end

    context "with eshop (Stripe) sales" do
      it "deducts paid StripePaymentItems from disponibles" do
        payment = StripePayment.create!(stripe_payment_id: "pi_test_avail_1", status: "paid", amount: 5000, currency: "eur")
        StripePaymentItem.create!(stripe_payment: payment, produit: produit, quantity: 1, unit_amount: 5000)

        result = produit.statut_disponibilite(today, today)
        expect(result[:vendus_eshop]).to eq(1)
        expect(result[:vendus]).to eq(1)
        expect(result[:disponibles]).to eq(2)
      end

      it "does not count pending (unpaid) StripePaymentItems" do
        payment = StripePayment.create!(stripe_payment_id: "pi_test_avail_2", status: "pending", amount: 5000, currency: "eur")
        StripePaymentItem.create!(stripe_payment: payment, produit: produit, quantity: 1, unit_amount: 5000)

        result = produit.statut_disponibilite(today, today)
        expect(result[:vendus_eshop]).to eq(0)
        expect(result[:disponibles]).to eq(3)
      end

      it "combines boutique and eshop sales" do
        commande = build_boutique_commande
        Article.create!(commande: commande, produit: produit, quantite: 1, locvente: "vente", prix: 50, total: 50)

        payment = StripePayment.create!(stripe_payment_id: "pi_test_avail_3", status: "paid", amount: 5000, currency: "eur")
        StripePaymentItem.create!(stripe_payment: payment, produit: produit, quantity: 1, unit_amount: 5000)

        result = produit.statut_disponibilite(today, today)
        expect(result[:vendus]).to eq(2)
        expect(result[:disponibles]).to eq(1)
      end
    end
  end

  describe "#update_today_availability" do
    let!(:profile) { Profile.create!(prenom: "Vendeur", nom: "Test") }

    it "sets today_availability to true when stock is available" do
      produit = Produit.create!(nom: "En stock", quantite: 2)
      # Force recalculation after creation
      result = produit.update_today_availability
      expect(result).to be(true)
      expect(produit.reload.today_availability).to be(true)
    end

    it "sets today_availability to false when all stock is sold" do
      produit = Produit.create!(nom: "Rupture", quantite: 1)
      payment = StripePayment.create!(stripe_payment_id: "pi_avail_sold_1", status: "paid", amount: 5000, currency: "eur")
      StripePaymentItem.create!(stripe_payment: payment, produit: produit, quantity: 1, unit_amount: 5000)

      result = produit.update_today_availability
      expect(result).to be(false)
      expect(produit.reload.today_availability).to be(false)
    end
  end
end
