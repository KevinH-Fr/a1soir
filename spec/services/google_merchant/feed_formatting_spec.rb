# frozen_string_literal: true

require "rails_helper"

RSpec.describe GoogleMerchant::FeedFormatting do
  let(:produit) { instance_double(Produit, id: 195) }

  describe ".item_id" do
    it "returns produit-{id} by default" do
      expect(described_class.item_id(produit)).to eq("produit-195")
    end

    it "respects MERCHANT_FEED_ID_PREFIX" do
      old = ENV["MERCHANT_FEED_ID_PREFIX"]
      ENV["MERCHANT_FEED_ID_PREFIX"] = "sku"
      expect(described_class.item_id(produit)).to eq("sku-195")
    ensure
      if old
        ENV["MERCHANT_FEED_ID_PREFIX"] = old
      else
        ENV.delete("MERCHANT_FEED_ID_PREFIX")
      end
    end
  end

  describe ".format_price_eur" do
    it "formats amounts with two decimals and EUR suffix" do
      expect(described_class.format_price_eur(695)).to eq("695.00 EUR")
      expect(described_class.format_price_eur(129.5)).to eq("129.50 EUR")
    end
  end

  describe ".item_group_id" do
    let(:long_handle) { "harper-robe-longue-fourreau-jersey-plisse-perles-fente" }

    it "returns handle unchanged when within 50 characters" do
      produit = instance_double(Produit, id: 1, handle: "robe-flux-merchant")
      expect(described_class.item_group_id(produit)).to eq("robe-flux-merchant")
    end

    it "returns a deterministic id of at most 50 characters for long handles" do
      produit = instance_double(Produit, id: 1, handle: long_handle)
      result = described_class.item_group_id(produit)

      expect(result.length).to be <= 50
      expect(result).to match(/\A[a-zA-Z0-9_-]+\z/)
      expect(described_class.item_group_id(produit)).to eq(result)
    end

    it "returns the same item_group_id for variants sharing a handle" do
      handle = long_handle
      produit_a = instance_double(Produit, id: 10, handle: handle)
      produit_b = instance_double(Produit, id: 11, handle: handle)

      expect(described_class.item_group_id(produit_a)).to eq(described_class.item_group_id(produit_b))
    end

    it "falls back to group-{id} when handle is blank" do
      produit = instance_double(Produit, id: 99, handle: nil)
      expect(described_class.item_group_id(produit)).to eq("group-99")
    end
  end

  describe ".normalize_item_group_id" do
    it "shortens handles longer than 50 characters with a stable hash suffix" do
      raw = "harper-robe-longue-fourreau-jersey-plisse-perles-fente"
      result = described_class.normalize_item_group_id(raw)

      expect(raw.length).to be > 50
      expect(result.length).to eq(50)
      expect(result).to end_with("-#{Digest::SHA256.hexdigest(raw)[0, 7]}")
    end
  end

  describe ".image_link_url" do
    it "returns a Cloudinary image URL with merchant width transform" do
      blob = instance_double(ActiveStorage::Blob, key: "abc123")
      url = described_class.image_link_url(blob)

      expect(url).to eq(
        "https://res.cloudinary.com/dukne3lhz/image/upload/q_auto,f_auto,w_1200/abc123"
      )
    end

    it "returns nil when blob is nil" do
      expect(described_class.image_link_url(nil)).to be_nil
    end
  end

  describe ".additional_image_link_urls" do
    let(:primary_blob) { instance_double(ActiveStorage::Blob, key: "primary-key") }
    let(:gallery_blob_a) { instance_double(ActiveStorage::Blob, key: "gallery-a") }
    let(:gallery_blob_b) { instance_double(ActiveStorage::Blob, key: "gallery-b") }
    let(:attachment_a) { double(blob: gallery_blob_a) }
    let(:attachment_b) { double(blob: gallery_blob_b) }
    let(:image1) { double(attached?: true, blob: primary_blob) }
    let(:produit) do
      double(
        image1: image1,
        images: images
      )
    end

    context "when images are not attached" do
      let(:images) { double(attached?: false) }

      it "returns an empty array" do
        expect(described_class.additional_image_link_urls(produit)).to eq([])
      end
    end

    context "when images are attached" do
      let(:images) { double(attached?: true) }

      it "returns gallery URLs excluding the primary image" do
        allow(images).to receive(:map) { |&block| [attachment_a, attachment_b].map(&block) }

        urls = described_class.additional_image_link_urls(produit)

        expect(urls).to eq([
          "https://res.cloudinary.com/dukne3lhz/image/upload/q_auto,f_auto,w_1200/gallery-a",
          "https://res.cloudinary.com/dukne3lhz/image/upload/q_auto,f_auto,w_1200/gallery-b"
        ])
      end

      it "excludes blobs with the same key as image1" do
        duplicate_attachment = double(blob: primary_blob)
        allow(images).to receive(:map) { |&block| [duplicate_attachment, attachment_a].map(&block) }

        urls = described_class.additional_image_link_urls(produit)

        expect(urls).to eq([
          "https://res.cloudinary.com/dukne3lhz/image/upload/q_auto,f_auto,w_1200/gallery-a"
        ])
      end
    end
  end

  describe ".video_link_url" do
    it "returns an mp4 Cloudinary URL when video1 is attached" do
      blob = instance_double(ActiveStorage::Blob, key: "video-key")
      video1 = double(attached?: true, blob: blob)
      produit = double(video1: video1)

      expect(described_class.video_link_url(produit)).to eq(
        "https://res.cloudinary.com/dukne3lhz/video/upload/q_auto,w_1200,f_mp4/video-key.mp4"
      )
    end

    it "returns nil when video1 is not attached" do
      video1 = double(attached?: false)
      produit = double(video1: video1)

      expect(described_class.video_link_url(produit)).to be_nil
    end
  end
end
