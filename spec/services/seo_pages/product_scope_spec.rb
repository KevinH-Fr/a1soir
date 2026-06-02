# frozen_string_literal: true

require "rails_helper"

RSpec.describe SeoPages::ProductScope do
  let!(:robes_longues) { CategorieProduit.create!(nom: "robes de mariée longues") }
  let!(:category) { robes_longues }
  let(:page) do
    {
      product_filters: {
        category_names: [category.nom]
      }
    }
  end

  def create_product(name:, handle: nil, taille: nil, image_bytes: "product-image")
    product = Produit.create!(
      nom: name,
      prixvente: 100,
      eshop: true,
      actif: true,
      today_availability: true,
      quantite: 1,
      handle: handle || "#{name.parameterize}-#{SecureRandom.hex(4)}",
      taille: taille
    )
    product.categorie_produits << category
    if image_bytes
      product.image1.attach(
        io: StringIO.new(image_bytes),
        filename: "#{name.parameterize}.jpg",
        content_type: "image/jpeg"
      )
    end
    product
  end

  it "limits the selection to 6 products" do
    8.times { |index| create_product(name: "Robe #{index}") }

    expect(described_class.call(page).size).to eq(6)
  end

  it "excludes products already used in section images" do
    products = 8.times.map { |index| create_product(name: "Robe #{index}") }
    excluded = products.first(2).map(&:id)

    result = described_class.call(page, exclude_product_ids: excluded)

    expect(result.map(&:id)).not_to include(*excluded)
    expect(result.size).to eq(6)
  end

  it "returns only one product per handle" do
    shared_handle = "robe-partagee-#{SecureRandom.hex(4)}"
    taille_s = Taille.create!(nom: "S-#{SecureRandom.hex(2)}")
    taille_m = Taille.create!(nom: "M-#{SecureRandom.hex(2)}")

    create_product(name: "Robe taille S", handle: shared_handle, taille: taille_s)
    create_product(name: "Robe taille M", handle: shared_handle, taille: taille_m)
    create_product(name: "Autre robe")

    result = described_class.call(page)

    expect(result.size).to eq(2)
    expect(result.map(&:handle).uniq).to eq([shared_handle, result.last.handle])
  end

  it "orders like the public catalogue: coups de coeur first, then most recently updated" do
    base_time = Time.current
    zebra = create_product(name: "Zebra robe", image_bytes: "z")
    zebra.update_columns(updated_at: base_time - 3.days)
    recent = create_product(name: "Robe récente", image_bytes: "r")
    recent.update_columns(updated_at: base_time - 1.day)
    star = create_product(name: "Ancienne vedette", image_bytes: "c")
    star.update_columns(coup_de_coeur: true, updated_at: base_time - 10.days)

    result = described_class.call(page)

    expect(result.map(&:id)).to eq([star.id, recent.id, zebra.id])
  end

  it "filters products by slug keyword when present" do
    page = SeoPages::Registry.find("robe-de-mariee-boheme", scope: "guides")
    create_product(name: "Robe bohème fluide")
    create_product(name: "Robe princesse classique")

    result = described_class.call(page)

    expect(result.map(&:nom)).to eq(["Robe bohème fluide"])
  end
end
