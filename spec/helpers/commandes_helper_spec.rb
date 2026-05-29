# frozen_string_literal: true

require "rails_helper"

RSpec.describe CommandesHelper, type: :helper do
  let(:client) do
    Client.create!(
      nom: "Durand",
      prenom: "Bob",
      propart: "particulier",
      intitule: Client::INTITULE_OPTIONS.first,
      mail: "helper-cmd-#{SecureRandom.hex(4)}@test.com"
    )
  end

  let(:profile) { Profile.create!(prenom: "Vendeur", nom: "Helper") }

  let(:eshop_commande) do
    Commande.create!(
      client: client,
      profile: profile,
      nom: "E-shop helper",
      montant: 100,
      devis: false,
      type_locvente: "vente",
      eshop: true
    )
  end

  describe "#frais_livraison_stripe_euros" do
    it "converts centimes to euros" do
      StripePayment.create!(
        commande: eshop_commande,
        stripe_payment_id: "pi_liv_#{SecureRandom.hex(6)}",
        amount: 6500,
        currency: "eur",
        status: "paid",
        frais_livraison_centimes: 950
      )

      expect(helper.frais_livraison_stripe_euros(eshop_commande.reload)).to eq(9.5)
    end

    it "returns 0 when there is no stripe payment" do
      expect(helper.frais_livraison_stripe_euros(eshop_commande)).to eq(0)
    end
  end

  describe "#pdf_afficher_paiements?" do
    it "is true for e-shop with paid stripe payment and no manual payments" do
      StripePayment.create!(
        commande: eshop_commande,
        stripe_payment_id: "pi_pdf_#{SecureRandom.hex(6)}",
        amount: 6000,
        currency: "eur",
        status: "paid"
      )

      expect(helper.pdf_afficher_paiements?(eshop_commande.reload)).to be(true)
    end

    it "is false for e-shop without paid stripe payment" do
      expect(helper.pdf_afficher_paiements?(eshop_commande)).to be(false)
    end
  end

  describe "#pdf_afficher_livraison?" do
    it "is true when e-shop has a stripe payment record" do
      StripePayment.create!(
        commande: eshop_commande,
        stripe_payment_id: "pi_liv2_#{SecureRandom.hex(6)}",
        amount: 6000,
        currency: "eur",
        status: "paid"
      )

      expect(helper.pdf_afficher_livraison?(eshop_commande.reload)).to be(true)
    end
  end
end
