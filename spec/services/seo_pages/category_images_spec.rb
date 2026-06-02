# frozen_string_literal: true

require "rails_helper"

RSpec.describe SeoPages::CategoryImages do
  let!(:robes_courtes) { CategorieProduit.create!(nom: "robes de mariée courtes") }
  let!(:robes_longues) { CategorieProduit.create!(nom: "robes de mariée longues") }
  let!(:costume) { CategorieProduit.create!(nom: "costume") }
  let!(:smokings) { CategorieProduit.create!(nom: "smokings") }
  let!(:robes_soiree_courtes) { CategorieProduit.create!(nom: "robes courtes") }
  let!(:robes_soiree_longues) { CategorieProduit.create!(nom: "robes longues") }
  let!(:enfants) { CategorieProduit.create!(nom: "enfants") }

  def create_product(name:, categories:, image_bytes: nil, video_bytes: nil, description: nil)
    product = Produit.create!(
      nom: name,
      description: description,
      prixvente: 100,
      eshop: true,
      actif: true,
      today_availability: true,
      quantite: 1,
      handle: "#{name.parameterize}-#{SecureRandom.hex(4)}"
    )
    product.categorie_produits << categories
    if image_bytes
      product.image1.attach(
        io: StringIO.new(image_bytes),
        filename: "#{name.parameterize}.jpg",
        content_type: "image/jpeg"
      )
    end
    if video_bytes
      product.video1.attach(
        io: StringIO.new(video_bytes),
        filename: "#{name.parameterize}.mp4",
        content_type: "video/mp4"
      )
    end
    product
  end

  describe ".call" do
    it "assigns a unique product image per section" do
      create_product(name: "Robe courte A", categories: [robes_courtes], image_bytes: "image-a")
      create_product(name: "Robe courte B", categories: [robes_courtes], image_bytes: "image-b")
      create_product(name: "Robe longue A", categories: [robes_longues], image_bytes: "image-c")

      page = SeoPages::Registry.find("robe-de-mariee-cannes", scope: "local")
      result = described_class.call(page, section_keys: %w[boutique collections services])

      blob_ids = result.values.map { |section| section[:image]&.blob&.id }.compact
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

    it "matches princesse section on product title only, not description" do
      create_product(
        name: "Robe sirène dentelle",
        description: "Jupe princesse et volume au bas",
        categories: [robes_longues],
        image_bytes: "sirene-princesse-desc"
      )
      princesse_product = create_product(
        name: "Robe princesse volume",
        description: "Ligne épurée",
        categories: [robes_longues],
        image_bytes: "princesse-title"
      )

      page = SeoPages::Registry.find("robe-de-mariee-morphologie", scope: "guides")
      result = described_class.call(page, section_keys: %w[princesse])

      expect(result.dig("princesse", :product_id)).to eq(princesse_product.id)
    end

    it "returns no images when no products are available" do
      page = SeoPages::Registry.find("robe-de-mariee-morphologie", scope: "guides")

      result = described_class.call(page, section_keys: %w[sirene])

      expect(result).to eq({})
    end

    it "assigns a boutique visual to access sections when products are available" do
      create_product(name: "Robe boutique cannes", categories: [robes_courtes], image_bytes: "boutique-image")

      page = SeoPages::Registry.find("robe-de-mariee-cannes", scope: "local")
      result = described_class.call(page, section_keys: %w[acces boutique])

      expect(result["acces"]).to be_present
      expect(result["boutique"]).to be_present
    end

    it "falls back to any available product when section keywords do not match" do
      create_product(name: "Robe mariée classique", categories: [robes_longues], image_bytes: "robe-image")

      page = SeoPages::Registry.find("comment-choisir-sa-robe-de-mariee", scope: "guides")
      result = described_class.call(page, section_keys: %w[delais])

      expect(result["delais"]).to be_present
      expect(result.dig("delais", :image)).to be_attached
    end

    it "never reuses the same image blob across sections on robe invitee mariage" do
      create_product(name: "Robe invitée A", categories: [robes_courtes], image_bytes: "invitee-a")
      create_product(name: "Robe invitée B", categories: [robes_longues], image_bytes: "invitee-b")

      page = SeoPages::Registry.find("robe-invitee-mariage", scope: "guides")
      result = described_class.call(page, section_keys: %w[dresscode couleurs location accessoires])

      blob_ids = result.values.filter_map { |section| section[:image]&.blob&.id }.compact
      expect(blob_ids.uniq.size).to eq(blob_ids.size)
      expect(result.size).to be <= 2
    end

    it "picks a product from the enfants category for the enfants section on costume mariage cannes" do
      create_product(name: "Costume homme", categories: [costume], image_bytes: "costume-img")
      enfant_product = create_product(name: "Costume garçon", categories: [enfants], image_bytes: "enfant-img")

      page = SeoPages::Registry.find("costume-mariage-cannes", scope: "local")
      result = described_class.call(page, section_keys: %w[collections enfants])

      expect(result.dig("enfants", :product_id)).to eq(enfant_product.id)
      expect(result.dig("enfants", :product_id)).not_to eq(result.dig("collections", :product_id))
    end

    it "fills morphologie when more sections than unique products on comment choisir" do
      5.times do |index|
        create_product(
          name: "Robe mariée modèle #{index}",
          categories: [robes_longues],
          image_bytes: "robe-#{index}"
        )
      end

      page = SeoPages::Registry.find("comment-choisir-sa-robe-de-mariee", scope: "guides")
      section_keys = %w[style budget delais essayage morphologie erreurs histoire]
      result = described_class.call(page, section_keys: section_keys)

      expect(result.keys).to match_array(section_keys)
      expect(result["morphologie"][:image]).to be_attached
    end

    it "picks different products for sections that share broad wedding keywords" do
      6.times do |index|
        create_product(
          name: "Robe mariée modèle #{index}",
          categories: [index.even? ? robes_courtes : robes_longues],
          image_bytes: "robe-#{index}"
        )
      end

      page = SeoPages::Registry.find("robe-de-mariee-cannes", scope: "local")
      result = described_class.call(page, section_keys: %w[histoire boutique services])

      product_ids = result.values.filter_map { |section| section[:product_id] }
      expect(product_ids.uniq.size).to eq(product_ids.size)
    end

    it "varies the hero section product between pages with the same section key" do
      4.times do |index|
        create_product(
          name: "Robe mariée variante #{index}",
          categories: [robes_longues],
          image_bytes: "variant-#{index}"
        )
      end

      cannes = SeoPages::Registry.find("robe-de-mariee-cannes", scope: "local")
      essayage = SeoPages::Registry.find("essayage-robe-de-mariee-cannes", scope: "local")

      cannes_boutique = described_class.call(cannes, section_keys: %w[boutique]).dig("boutique", :product_id)
      essayage_boutique = described_class.call(essayage, section_keys: %w[boutique]).dig("boutique", :product_id)

      expect(cannes_boutique).to be_present
      expect(essayage_boutique).to be_present
      expect(cannes_boutique).not_to eq(essayage_boutique)
    end

    it "uses video media when the best matching product has a video" do
      create_product(name: "Robe photo seule", categories: [robes_courtes], image_bytes: "photo-only")
      create_product(
        name: "Robe mariée vidéo boutique",
        categories: [robes_courtes],
        image_bytes: "video-poster",
        video_bytes: "video-content"
      )

      page = SeoPages::Registry.find("robe-de-mariee-cannes", scope: "local")
      result = described_class.call(page, section_keys: %w[boutique])

      expect(result.dig("boutique", :media_type)).to eq(:video)
      expect(result.dig("boutique", :video)).to be_attached
      expect(result.dig("boutique", :image)).to be_attached
    end

    it "falls back to image when no product with video matches" do
      create_product(name: "Robe sans vidéo", categories: [robes_courtes], image_bytes: "image-only")

      page = SeoPages::Registry.find("robe-de-mariee-cannes", scope: "local")
      result = described_class.call(page, section_keys: %w[boutique])

      expect(result.dig("boutique", :media_type)).to eq(:image)
      expect(result.dig("boutique", :video)).to be_nil
    end
  end
end
