# frozen_string_literal: true

require "rails_helper"

RSpec.describe PdfHelper, type: :helper do
  describe "#pdf_image_src_for_body" do
    it "returns a Cloudinary URL with width for blobs" do
      blob = instance_double(ActiveStorage::Blob, key: "abc123")

      src = helper.pdf_image_src_for_body(blob, width: 80)

      expect(src).to eq(
        "https://res.cloudinary.com/dukne3lhz/image/upload/q_auto,f_auto,w_80/abc123"
      )
      expect(src).not_to start_with("data:")
    end

    it "returns base64 for local fallback paths" do
      src = helper.pdf_image_src_for_body("/images/no_photo.png", width: 80)

      expect(src).to start_with("data:image/png;base64,")
    end
  end

  describe "#pdf_image_src_embedded" do
    it "returns base64 for blobs" do
      blob = instance_double(
        ActiveStorage::Blob,
        content_type: "image/jpeg",
        download: "fake-image-bytes"
      )

      src = helper.pdf_image_src_embedded(blob)

      expect(src).to start_with("data:image/jpeg;base64,")
    end
  end

  describe "#pdf_product_thumb_tag" do
    it "does not embed full blob data in the tag" do
      blob = instance_double(ActiveStorage::Blob, key: "thumb-key")

      html = helper.pdf_product_thumb_tag(blob, width: 40, class: "pdf-thumb-sm")

      expect(html).to include("w_40/thumb-key")
      expect(html).not_to include("base64")
    end
  end
end
