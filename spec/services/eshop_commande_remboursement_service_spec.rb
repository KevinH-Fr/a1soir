# frozen_string_literal: true

require "rails_helper"

RSpec.describe EshopCommandeRemboursementService do
  let(:client) do
    Client.create!(
      nom: "Martin",
      prenom: "Alice",
      propart: "particulier",
      intitule: Client::INTITULE_OPTIONS.first,
      mail: "remb-svc-#{SecureRandom.hex(4)}@test.com"
    )
  end

  let(:profile) { Profile.create!(prenom: "Vendeur", nom: "Remb") }

  let!(:produit) do
    Produit.create!(
      nom: "Robe remb",
      prixvente: 60,
      quantite: 2,
      today_availability: false,
      eshop: true
    )
  end

  let!(:commande) do
    Commande.create!(
      client: client,
      profile: profile,
      nom: "E-shop remb",
      montant: 65,
      devis: false,
      type_locvente: "vente",
      eshop: true
    )
  end

  let!(:stripe_payment) do
    StripePayment.create!(
      commande: commande,
      stripe_payment_id: "pi_remb_#{SecureRandom.hex(6)}",
      amount: 6500,
      currency: "eur",
      status: "paid",
      frais_livraison_centimes: 500
    )
  end

  let!(:stripe_item) do
    StripePaymentItem.create!(
      stripe_payment: stripe_payment,
      produit: produit,
      quantity: 1,
      unit_amount: 6000
    )
  end

  subject(:result) { described_class.new(commande.reload).call(stripe_payment_item_ids: [stripe_item.id], include_shipping: true) }

  describe "#call" do
    it "sets devis, creates remboursement AvoirRemb, marks remboursee_eshop?" do
      expect(result.success?).to be(true)
      expect(result.already_done).to be(false)

      commande.reload
      expect(commande.devis?).to be(true)
      expect(commande.remboursee_eshop?).to be(true)

      remb = commande.avoir_rembs.remb_only.sole
      expect(remb.montant).to eq(65.0)
      expect(remb.nature).to eq(EshopCommandeRemboursementService::NATURE_REMBOURSEMENT)
      expect(stripe_item.reload.refunded_at).to be_present
      expect(stripe_payment.reload.amount).to eq(6500)
      expect(stripe_payment.status).to eq("paid")
    end

    it "is idempotent on second call" do
      described_class.new(commande).call(stripe_payment_item_ids: [stripe_item.id], include_shipping: true)
      second = described_class.new(commande.reload).call(stripe_payment_item_ids: [stripe_item.id], include_shipping: true)

      expect(second.success?).to be(true)
      expect(second.already_done).to be(true)
      expect(commande.avoir_rembs.remb_only.count).to eq(1)
    end

    it "restores today_availability when stock allows" do
      produit.update!(today_availability: false)
      expect { result }.to change { produit.reload.today_availability? }.from(false).to(true)
    end

    context "when not eshop" do
      before { commande.update!(eshop: false) }

      it "fails" do
        expect(result.success?).to be(false)
        expect(result.error_key).to eq(:not_eshop)
      end
    end

    context "when stripe not paid" do
      before { stripe_payment.update!(status: "failed") }

      it "fails" do
        expect(result.success?).to be(false)
        expect(result.error_key).to eq(:stripe_not_paid)
      end
    end
  end

  describe "#call(article:)" do
    let!(:produit_b) do
      Produit.create!(nom: "Pochette remb", prixvente: 20, quantite: 2, eshop: true)
    end

    let!(:article_a) do
      Article.create!(commande: commande, produit: produit, quantite: 1, prix: 60, total: 60, locvente: "vente")
    end

    let!(:article_b) do
      Article.create!(commande: commande, produit: produit_b, quantite: 1, prix: 20, total: 20, locvente: "vente")
    end

    let!(:stripe_item_b) do
      StripePaymentItem.create!(
        stripe_payment: stripe_payment,
        produit: produit_b,
        quantity: 1,
        unit_amount: 2000
      )
    end

    before { stripe_payment.update!(amount: 8500) }

    it "refunds one line without deleting the Stripe payment or item" do
      result = described_class.new(commande.reload).call(article: article_a)

      expect(result.success?).to be(true)
      expect(Article.exists?(article_a.id)).to be(false)
      expect(Article.exists?(article_b.id)).to be(true)

      expect(stripe_item.reload.refunded_at).to be_present
      expect(stripe_item_b.reload.refunded_at).to be_nil
      expect(StripePayment.exists?(stripe_payment.id)).to be(true)
      expect(stripe_payment.reload.amount).to eq(8500)
      expect(stripe_payment.status).to eq("paid")

      commande.reload
      expect(commande.devis?).to be(false)
      expect(commande.remboursee_eshop?).to be(false)
      expect(commande.avoir_rembs.remb_only.sole.montant).to eq(60.0)

      expect(produit.total_vendus_eshop).to eq(0)
      expect(produit_b.total_vendus_eshop).to eq(1)
    end

    it "refunds remaining including shipping when the last product is removed" do
      described_class.new(commande.reload).call(article: article_a)
      result = described_class.new(commande.reload).call(article: article_b.reload)

      expect(result.success?).to be(true)
      expect(Article.exists?(article_b.id)).to be(false)
      commande.reload
      expect(commande.devis?).to be(true)
      expect(commande.remboursee_eshop?).to be(true)
      expect(commande.avoir_rembs.remb_only.sum(:montant)).to eq(85.0)
      expect(stripe_item_b.reload.refunded_at).to be_present
      expect(stripe_payment.reload.amount).to eq(8500)
    end

    it "refunds only selected products in a single AvoirRemb" do
      result = described_class.new(commande.reload).call(stripe_payment_item_ids: [stripe_item.id])

      expect(result.success?).to be(true)
      expect(Article.exists?(article_a.id)).to be(false)
      expect(Article.exists?(article_b.id)).to be(true)
      expect(stripe_item.reload.refunded_at).to be_present
      expect(stripe_item_b.reload.refunded_at).to be_nil
      expect(commande.reload.devis?).to be(false)
      expect(commande.avoir_rembs.remb_only.count).to eq(1)
      expect(commande.avoir_rembs.remb_only.sole.montant).to eq(60.0)
    end

    it "creates one refund line including shipping when every remaining product is selected" do
      result = described_class.new(commande.reload).call(
        stripe_payment_item_ids: [stripe_item.id, stripe_item_b.id],
        include_shipping: true
      )

      expect(result.success?).to be(true)
      expect(Article.exists?(article_a.id)).to be(false)
      expect(Article.exists?(article_b.id)).to be(false)
      commande.reload
      expect(commande.devis?).to be(true)
      expect(commande.avoir_rembs.remb_only.sole.montant).to eq(85.0)
    end

    it "can add shipping to a partial product refund" do
      result = described_class.new(commande.reload).call(
        stripe_payment_item_ids: [stripe_item.id],
        include_shipping: true
      )

      expect(result.success?).to be(true)
      expect(Article.exists?(article_b.id)).to be(true)
      expect(commande.reload.devis?).to be(false)
      expect(commande.avoir_rembs.remb_only.sole.montant).to eq(65.0)
    end

    it "fails when no product is selected" do
      result = described_class.new(commande.reload).call(stripe_payment_item_ids: [])

      expect(result.success?).to be(false)
      expect(result.error_key).to eq(:no_items)
    end
  end
end
