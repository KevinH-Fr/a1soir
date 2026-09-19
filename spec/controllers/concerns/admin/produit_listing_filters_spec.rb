# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::ProduitListingFilters do
  let(:host) { Class.new { include Admin::ProduitListingFilters }.new }

  describe ".normalize_filter_values" do
    it "accepts a scalar, an array, and blanks" do
      expect(described_class.normalize_filter_values("12")).to eq(%w[12])
      expect(described_class.normalize_filter_values([12, "12", "", nil])).to eq(%w[12])
    end
  end

  describe "#apply_categorie_filter" do
    it "keeps products that match any of the selected categories" do
      cat_a = CategorieProduit.create!(nom: "cat-a-#{SecureRandom.hex(2)}")
      cat_b = CategorieProduit.create!(nom: "cat-b-#{SecureRandom.hex(2)}")
      produit_a = Produit.create!(nom: "A", prixvente: 10, quantite: 1)
      produit_b = Produit.create!(nom: "B", prixvente: 10, quantite: 1)
      produit_a.categorie_produits << cat_a
      produit_b.categorie_produits << cat_b

      scoped = host.apply_categorie_filter(Produit.all, [cat_a.id, cat_b.id])

      expect(scoped).to include(produit_a, produit_b)
    end
  end

  describe "#apply_type_produit_filter" do
    it "keeps products of any selected type" do
      type_a = TypeProduit.create!(nom: "type-a-#{SecureRandom.hex(2)}")
      type_b = TypeProduit.create!(nom: "type-b-#{SecureRandom.hex(2)}")
      produit_a = Produit.create!(nom: "A", prixvente: 10, quantite: 1, type_produit_id: type_a.id)
      produit_b = Produit.create!(nom: "B", prixvente: 10, quantite: 1, type_produit_id: type_b.id)

      scoped = host.apply_type_produit_filter(Produit.all, [type_a.id, type_b.id])

      expect(scoped).to include(produit_a, produit_b)
    end
  end
end
