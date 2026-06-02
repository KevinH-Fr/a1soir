# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#cloudinary_attachment_url" do
    it "returns an optimized Cloudinary URL for a blob" do
      blob = instance_double(ActiveStorage::Blob, key: "robe-categorie-abc")

      url = helper.cloudinary_attachment_url(blob, width: 800)

      expect(url).to eq(
        "https://res.cloudinary.com/dukne3lhz/image/upload/q_auto,f_auto,w_800/robe-categorie-abc"
      )
    end

    it "returns nil for static image paths" do
      expect(helper.cloudinary_attachment_url("/images/cat_costume.webp", width: 800)).to be_nil
    end
  end

  describe "PagesHelper#collection_card_image_source" do
    it "returns a Cloudinary URL for ActiveStorage attachments" do
      blob = instance_double(ActiveStorage::Blob, key: "card-key-1")
      attachment = instance_double(ActiveStorage::Attached::One, attached?: true, blob: blob)

      expect(helper.collection_card_image_source(attachment, width: 800)).to include("w_800/card-key-1")
    end

    it "returns a local path for static assets" do
      expect(helper.collection_card_image_source("/images/cat_costume.webp")).to eq("/images/cat_costume.webp")
    end
  end
end
