# frozen_string_literal: true

require "rails_helper"

RSpec.describe GoogleMerchant::ApparelAttributes do
  def produit_with_categories(*category_names, description: nil)
    categories = category_names.map { |name| CategorieProduit.create!(nom: name) }
    Produit.create!(
      nom: "Produit test #{SecureRandom.hex(3)}",
      description: description,
      prixvente: 10,
      categorie_produits: categories
    )
  end

  describe ".age_group_for" do
    it "returns kids when the product has the enfants category" do
      produit = produit_with_categories("enfants")
      expect(described_class.age_group_for(produit)).to eq("kids")
    end

    it "returns adult for non-enfants categories" do
      produit = produit_with_categories("robes courtes")
      expect(described_class.age_group_for(produit)).to eq("adult")
    end
  end

  describe ".gender_for" do
    it "returns female for female categories" do
      produit = produit_with_categories("robes courtes")
      expect(described_class.gender_for(produit)).to eq("female")
    end

    it "returns female for accessoires femmes" do
      produit = produit_with_categories("accessoires femmes")
      expect(described_class.gender_for(produit)).to eq("female")
    end

    it "returns female for ensembles pantalons" do
      produit = produit_with_categories("ensembles pantalons")
      expect(described_class.gender_for(produit)).to eq("female")
    end

    it "returns male for accessoires (not confused with accessoires femmes token)" do
      produit = produit_with_categories("accessoires")
      expect(described_class.gender_for(produit)).to eq("male")
      expect((["accessoires"] & described_class::FEMALE_CATEGORIES)).to be_empty
    end

    it "returns male for costume" do
      produit = produit_with_categories("costume")
      expect(described_class.gender_for(produit)).to eq("male")
    end

    it "returns male for enfants" do
      produit = produit_with_categories("enfants")
      expect(described_class.gender_for(produit)).to eq("male")
    end

    it "prefers female over accessoires when both categories are present" do
      produit = produit_with_categories("accessoires", "accessoires femmes")
      expect(described_class.gender_for(produit)).to eq("female")
    end

    context "with chaussures category" do
      it "returns male when description contains homme" do
        produit = produit_with_categories("chaussures", description: "<p>Chaussures vernies homme</p>")
        expect(described_class.gender_for(produit)).to eq("male")
      end

      it "returns female when description does not contain homme" do
        produit = produit_with_categories("chaussures", description: "<p>Escarpins soirée</p>")
        expect(described_class.gender_for(produit)).to eq("female")
      end

      it "ignores homme as substring inside another word" do
        produit = produit_with_categories("chaussures", description: "modèle féminin")
        expect(described_class.gender_for(produit)).to eq("female")
      end
    end

    it "returns unisex when no recognized category" do
      produit = Produit.create!(nom: "Sans catégorie", prixvente: 10)
      expect(described_class.gender_for(produit)).to eq("unisex")
    end
  end
end
