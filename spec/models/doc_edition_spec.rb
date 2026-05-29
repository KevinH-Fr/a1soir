# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocEdition do
  let(:client) do
    Client.create!(
      nom: "Martin",
      prenom: "Alice",
      propart: "particulier",
      intitule: Client::INTITULE_OPTIONS.first,
      mail: "doc-edition-#{SecureRandom.hex(4)}@test.com"
    )
  end

  let(:profile) { Profile.create!(prenom: "Vendeur", nom: "Test") }

  let(:boutique_commande) do
    Commande.create!(
      client: client,
      profile: profile,
      nom: "Boutique",
      montant: 100,
      devis: false,
      type_locvente: "vente",
      typeevent: Commande::EVENEMENTS_OPTIONS.first,
      eshop: false
    )
  end

  let(:eshop_commande) do
    Commande.create!(
      client: client,
      profile: profile,
      nom: "E-shop",
      montant: 100,
      devis: false,
      type_locvente: "vente",
      eshop: true
    )
  end

  describe ".document_types_for" do
    it "returns all document types for boutique commandes" do
      expect(described_class.document_types_for(boutique_commande)).to eq(DocEdition::DOCUMENT_TYPES)
    end

    it "returns only facture for e-shop commandes" do
      expect(described_class.document_types_for(eshop_commande)).to eq(["facture"])
    end

    it "returns all types when commande is nil" do
      expect(described_class.document_types_for(nil)).to eq(DocEdition::DOCUMENT_TYPES)
    end
  end

  describe "doc_type validation for e-shop" do
    it "allows facture" do
      edition = described_class.new(commande: eshop_commande, doc_type: "facture", edition_type: "pdf")
      expect(edition).to be_valid
    end

    it "rejects commande" do
      edition = described_class.new(commande: eshop_commande, doc_type: "commande", edition_type: "pdf")
      expect(edition).not_to be_valid
      expect(edition.errors[:doc_type]).to be_present
    end

    it "rejects facture simple" do
      edition = described_class.new(commande: eshop_commande, doc_type: "facture simple", edition_type: "pdf")
      expect(edition).not_to be_valid
    end

    it "allows any document type for boutique commandes" do
      edition = described_class.new(commande: boutique_commande, doc_type: "commande", edition_type: "pdf")
      expect(edition).to be_valid
    end
  end
end
