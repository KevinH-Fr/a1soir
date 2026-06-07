# frozen_string_literal: true

require "rails_helper"

RSpec.describe FiltersProduitsService do
  let!(:produit_vente_cher_location_pas_cher) do
    Produit.create!(
      nom: "Robe mixte",
      handle: "robe-mixte",
      prixvente: 200,
      prixlocation: 50,
      stripe_price_id: "price_mixte",
      eshop: true,
      today_availability: true,
      quantite: 1,
      actif: true
    )
  end

  let!(:produit_vente_pas_cher) do
    Produit.create!(
      nom: "Robe vente",
      handle: "robe-vente",
      prixvente: 80,
      prixlocation: 0,
      stripe_price_id: "price_vente",
      eshop: true,
      today_availability: true,
      quantite: 1,
      actif: true
    )
  end

  describe "prix + type Vente" do
    subject(:results) { described_class.new(nil, nil, nil, 100, "Vente", nil).call }

    it "filtre sur prixvente, pas sur prixlocation" do
      expect(results).to include(produit_vente_pas_cher)
      expect(results).not_to include(produit_vente_cher_location_pas_cher)
    end
  end

  describe "prix + type Location" do
    subject(:results) { described_class.new(nil, nil, nil, 100, "Location", nil).call }

    it "filtre sur prixlocation, pas sur prixvente" do
      expect(results).to include(produit_vente_cher_location_pas_cher)
      expect(results).not_to include(produit_vente_pas_cher)
    end
  end
end
