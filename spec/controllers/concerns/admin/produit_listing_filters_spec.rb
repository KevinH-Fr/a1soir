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

  describe "#apply_statut_filter" do
    let!(:actif_eshop_dispo) do
      Produit.create!(nom: "Actif eshop dispo", prixvente: 10, quantite: 1, actif: true, eshop: true)
    end
    let!(:archive_boutique) do
      produit = Produit.create!(nom: "Archive boutique", prixvente: 10, quantite: 0, actif: false, eshop: false)
      produit.update_column(:today_availability, false)
      produit
    end

    it "keeps active products published on the eshop and available today" do
      scoped = host.apply_statut_filter(Produit.all, %w[actif eshop dispo])

      expect(scoped).to include(actif_eshop_dispo)
      expect(scoped).not_to include(archive_boutique)
    end

    it "keeps archived products that are neither on the eshop nor available" do
      scoped = host.apply_statut_filter(Produit.all, %w[archive pas_eshop pas_dispo])

      expect(scoped).to contain_exactly(archive_boutique)
    end

    it "accepts the legacy actif value" do
      scoped = host.apply_statut_filter(Produit.all, "true")

      expect(scoped).to include(actif_eshop_dispo)
      expect(scoped).not_to include(archive_boutique)
    end
  end

  describe "#apply_catalogue_filter" do
    let!(:mariage) { Produit.create!(nom: "Robe mariage", prixvente: 10, quantite: 1) }
    let!(:costume) do
      Produit.create!(
        nom: "Habit epoque",
        prixvente: 10,
        quantite: 1,
        catalogue: Produit::CATALOGUE_COSTUME_EPOQUE_DEGUISEMENTS
      )
    end

    let!(:les_deux) do
      Produit.create!(
        nom: "Robe des deux",
        prixvente: 10,
        quantite: 1,
        catalogue: Produit::CATALOGUE_LES_DEUX
      )
    end

    it "keeps the wedding catalogue and products in both" do
      scoped = host.apply_catalogue_filter(Produit.all, Produit::CATALOGUE_TENUES_MARIAGE_SOIREE)

      expect(scoped).to include(mariage, les_deux)
      expect(scoped).not_to include(costume)
    end

    it "keeps the costume catalogue and products in both" do
      scoped = host.apply_catalogue_filter(Produit.all, Produit::CATALOGUE_COSTUME_EPOQUE_DEGUISEMENTS)

      expect(scoped).to include(costume, les_deux)
      expect(scoped).not_to include(mariage)
    end

    it "keeps every catalogue when the value is tous" do
      scoped = host.apply_catalogue_filter(Produit.all, described_class::CATALOGUE_FILTER_ALL)

      expect(scoped).to include(mariage, costume, les_deux)
    end
  end
end
