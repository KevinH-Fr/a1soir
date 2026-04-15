require "rails_helper"

RSpec.describe StripeProductService do
  let(:produit) do
    Produit.create!(
      nom: "Produit Stripe image",
      prixvente: 42,
      eshop: true,
      today_availability: true,
      quantite: 1
    )
  end

  let(:stripe_product) { instance_double("Stripe::Product", id: "prod_test_123") }
  let(:stripe_price) { instance_double("Stripe::Price", id: "price_test_123") }

  describe "#create_product_and_price" do
    it "sends a product image URL when image1 is attached" do
      produit.image1.attach(
        io: StringIO.new("fake-image-content"),
        filename: "product.jpg",
        content_type: "image/jpeg"
      )
      service = described_class.new(produit)

      allow(produit.image1).to receive(:url).and_return("https://cdn.example.com/product.jpg")
      allow(Stripe::Product).to receive(:create).and_return(stripe_product)
      allow(Stripe::Price).to receive(:create).and_return(stripe_price)

      service.create_product_and_price

      expect(produit.image1).to have_received(:url)
      expect(Stripe::Product).to have_received(:create).with(hash_including(images: ["https://cdn.example.com/product.jpg"]))
    end

    it "does not send images when no image is attached" do
      service = described_class.new(produit)

      allow(Stripe::Product).to receive(:create).and_return(stripe_product)
      allow(Stripe::Price).to receive(:create).and_return(stripe_price)

      service.create_product_and_price

      expect(Stripe::Product).to have_received(:create).with(hash_excluding(:images))
    end
  end

  describe "#update_product_and_price" do
    before do
      produit.update_columns(stripe_product_id: "prod_existing", stripe_price_id: "price_existing")
    end

    it "clears Stripe product images when no image is available" do
      service = described_class.new(produit)

      allow(Stripe::Product).to receive(:update).and_return(stripe_product)

      service.update_product_and_price

      expect(Stripe::Product).to have_received(:update).with("prod_existing", hash_including(images: []))
    end
  end

  describe "#archive_product_and_price" do
    it "disables Stripe price and product when Stripe IDs exist" do
      produit.update_columns(stripe_product_id: "prod_existing", stripe_price_id: "price_existing")
      service = described_class.new(produit)

      allow(Stripe::Price).to receive(:update)
      allow(Stripe::Product).to receive(:update)

      service.archive_product_and_price

      expect(Stripe::Price).to have_received(:update).with("price_existing", { active: false })
      expect(Stripe::Product).to have_received(:update).with("prod_existing", { active: false })
    end
  end
end
