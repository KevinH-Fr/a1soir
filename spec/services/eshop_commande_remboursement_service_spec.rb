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

  subject(:result) { described_class.new(commande.reload).call }

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
    end

    it "is idempotent on second call" do
      described_class.new(commande).call
      second = described_class.new(commande.reload).call

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
end
