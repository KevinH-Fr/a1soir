# frozen_string_literal: true

require "rails_helper"

RSpec.describe SeoPages::CategoryImages do
  let!(:robes_courtes) { CategorieProduit.create!(nom: "robes de mariée courtes") }
  let!(:robes_longues) { CategorieProduit.create!(nom: "robes de mariée longues") }
  let!(:costume) { CategorieProduit.create!(nom: "costume") }
  let!(:smokings) { CategorieProduit.create!(nom: "smokings") }
  let!(:robes_soiree_courtes) { CategorieProduit.create!(nom: "robes courtes") }
  let!(:robes_soiree_longues) { CategorieProduit.create!(nom: "robes longues") }

  def create_product(name:, categories:, image_bytes:)
    product = Produit.create!(
      nom: name,
      prixvente: 100,
      eshop: true,
      actif: true,
      today_availability: true,
      quantite: 1,
      handle: "#{name.parameterize}-#{SecureRandom.hex(4)}"
    )
    product.categorie_produits << categories
    product.image1.attach(
      io: StringIO.new(image_bytes),
      filename: "#{name.parameterize}.jpg",
      content_type: "image/jpeg"
    )
    product
  end

  describe ".call" do
    it "assigns a unique product image per section" do
      create_product(name: "Robe courte A", categories: [robes_courtes], image_bytes: "image-a")
      create_product(name: "Robe courte B", categories: [robes_courtes], image_bytes: "image-b")
      create_product(name: "Robe longue A", categories: [robes_longues], image_bytes: "image-c")

      page = SeoPages::Registry.find("robe-de-mariee-cannes", scope: "local")
      result = described_class.call(page, section_keys: %w[boutique collections services])

      blob_ids = result.values.map { |section| section[:image].blob.id }
      expect(blob_ids.uniq.size).to eq(blob_ids.size)
      expect(result.keys).to match_array(%w[boutique collections services])
    end

    it "picks products from matching categories for a suit guide" do
      smoking_product = create_product(name: "Smoking A", categories: [smokings], image_bytes: "smoking-a")
      costume_product = create_product(name: "Costume A", categories: [costume], image_bytes: "costume-a")

      page = SeoPages::Registry.find("smoking-ou-costume-mariage", scope: "guides")
      result = described_class.call(page, section_keys: %w[smoking costume])

      expect(result.dig("smoking", :image).blob.id).to eq(smoking_product.image1.blob.id)
      expect(result.dig("costume", :image).blob.id).to eq(costume_product.image1.blob.id)
    end

    it "uses a suit product for the men section on the gala guide" do
      create_product(name: "Robe gala", categories: [robes_soiree_longues], image_bytes: "robe-gala")
      costume_product = create_product(name: "Costume gala", categories: [costume], image_bytes: "costume-gala")

      page = SeoPages::Registry.find("tenue-gala-ceremonie", scope: "guides")
      result = described_class.call(page, section_keys: %w[femmes hommes])

      expect(result.dig("femmes", :image).blob.id).not_to eq(result.dig("hommes", :image).blob.id)
      expect(result.dig("hommes", :image).blob.id).to eq(costume_product.image1.blob.id)
    end

    it "uses style-specific products for the morphology guide" do
      sirene_product = create_product(name: "Robe sirène dentelle", categories: [robes_longues], image_bytes: "sirene")
      princesse_product = create_product(name: "Robe princesse volume", categories: [robes_longues], image_bytes: "princesse")
      fourreau_product = create_product(name: "Robe fourreau satin", categories: [robes_longues], image_bytes: "fourreau")

      page = SeoPages::Registry.find("robe-de-mariee-morphologie", scope: "guides")
      result = described_class.call(page, section_keys: %w[sirene princesse fourreau])

      expect(result.dig("sirene", :image).blob.id).to eq(sirene_product.image1.blob.id)
      expect(result.dig("princesse", :image).blob.id).to eq(princesse_product.image1.blob.id)
      expect(result.dig("fourreau", :image).blob.id).to eq(fourreau_product.image1.blob.id)
    end

    it "returns no images when no products are available" do
      page = SeoPages::Registry.find("robe-de-mariee-morphologie", scope: "guides")

      result = described_class.call(page, section_keys: %w[sirene])

      expect(result).to eq({})
    end

    it "skips access sections without illustrative image" do
      create_product(name: "Robe boutique", categories: [robes_courtes], image_bytes: "boutique-image")

      page = SeoPages::Registry.find("robe-de-mariee-cannes", scope: "local")
      result = described_class.call(page, section_keys: %w[acces boutique])

      expect(result["acces"]).to be_nil
      expect(result["boutique"]).to be_present
    end
  end
end
