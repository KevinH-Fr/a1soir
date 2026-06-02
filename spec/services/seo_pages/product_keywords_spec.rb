# frozen_string_literal: true

require "rails_helper"

RSpec.describe SeoPages::ProductKeywords do
  it "extracts bohème from a bohemian guide slug" do
    page = SeoPages::Registry.find("robe-de-mariee-boheme", scope: "guides")

    expect(described_class.call(page)).to eq(["boheme"])
    expect(described_class.search_string(page)).to eq("boheme")
  end

  it "returns nothing for a generic wedding guide slug" do
    page = SeoPages::Registry.find("comment-choisir-sa-robe-de-mariee", scope: "guides")

    expect(described_class.call(page)).to eq([])
  end

  it "prefers an explicit search term from the registry" do
    page = {
      slug: "robe-de-mariee-boheme",
      product_filters: { search_term: "dentelle" }
    }

    expect(described_class.call(page)).to eq(["dentelle"])
  end

  it "does not narrow category pages to smoking-only products" do
    page = SeoPages::Registry.find("smoking-ou-costume-mariage", scope: "guides")

    expect(described_class.call(page)).to eq([])
  end

  describe ".apply" do
    let!(:category) { CategorieProduit.create!(nom: "robes de mariée longues") }
    let(:page) { SeoPages::Registry.find("robe-de-mariee-boheme", scope: "guides") }
    let(:base_scope) do
      Produit.actif
             .eshop_diffusion
             .where(today_availability: true)
             .by_categories([category.id])
    end

    before do
      product = Produit.create!(
        nom: "Robe bohème",
        prixvente: 100,
        eshop: true,
        actif: true,
        today_availability: true,
        quantite: 1,
        handle: "robe-boheme-#{SecureRandom.hex(4)}"
      )
      product.categorie_produits << category
    end

    it "matches accent variants without incompatible or joins" do
      result = described_class.apply(base_scope, page)

      expect(result.pluck(:nom)).to eq(["Robe bohème"])
    end

    it "does not fail when scope has distinct, order and ransack joins on taille" do
      taille = Taille.create!(nom: "retouche-atelier")
      product = Produit.create!(
        nom: "Service atelier",
        prixvente: 50,
        eshop: true,
        actif: true,
        today_availability: true,
        quantite: 1,
        taille: taille,
        handle: "retouche-#{SecureRandom.hex(4)}"
      )
      product.categorie_produits << category

      scoped = base_scope.public_listing_order
      page = { slug: "test", product_filters: { search_term: "retouche" } }

      expect { described_class.apply(scoped, page).load }.not_to raise_error
      expect(described_class.apply(scoped, page).pluck(:id)).to eq([product.id])
    end
  end
end
