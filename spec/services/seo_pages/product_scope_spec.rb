# frozen_string_literal: true

require "rails_helper"

RSpec.describe SeoPages::ProductScope do
  let!(:robes_longues) { CategorieProduit.create!(nom: "robes de mariée longues") }
  let!(:category) { robes_longues }
  let(:page) do
    {
      product_filters: {
        category_names: ["robes de mariée courtes"]
      }
    }
  end

  def create_product(name:)
    product = Produit.create!(
      nom: name,
      prixvente: 100,
      eshop: true,
      actif: true,
      today_availability: true,
      quantite: 1,
      handle: "#{name.parameterize}-#{SecureRandom.hex(4)}"
    )
    product.categorie_produits << category
    product
  end

  it "limits the selection to 6 products" do
    8.times { |index| create_product(name: "Robe #{index}") }

    expect(described_class.call(page).size).to eq(6)
  end

  it "filters products by slug keyword when present" do
    page = SeoPages::Registry.find("robe-de-mariee-boheme", scope: "guides")
    create_product(name: "Robe bohème fluide")
    create_product(name: "Robe princesse classique")

    result = described_class.call(page)

    expect(result.map(&:nom)).to eq(["Robe bohème fluide"])
  end
end
