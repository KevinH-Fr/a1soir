# frozen_string_literal: true

require "rails_helper"

RSpec.describe PdfHelper, type: :helper do
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("fake-image-bytes"),
      filename: "thumb.jpg",
      content_type: "image/jpeg"
    )
  end

  describe "#pdf_image_src_for_body" do
    it "returns a Cloudinary URL with width for blobs" do
      src = helper.pdf_image_src_for_body(blob, width: 80)

      expect(src).to eq(
        "#{ApplicationHelper::CLOUDINARY_BASE_IMAGE_URL}/q_auto,f_auto,w_80/#{blob.key}"
      )
      expect(src).not_to start_with("data:")
    end

    it "accepts a custom quality for print PDFs" do
      src = helper.pdf_image_src_for_body(blob, width: 800, quality: 90)

      expect(src).to eq(
        "#{ApplicationHelper::CLOUDINARY_BASE_IMAGE_URL}/q_90,f_auto,w_800/#{blob.key}"
      )
    end

    it "returns base64 for local fallback paths" do
      src = helper.pdf_image_src_for_body("/images/no_photo.png", width: 80)

      expect(src).to start_with("data:image/png;base64,")
    end
  end

  describe "#pdf_image_src_embedded" do
    it "returns base64 for blobs" do
      src = helper.pdf_image_src_embedded(blob)

      expect(src).to start_with("data:image/jpeg;base64,")
    end
  end

  describe "#pdf_product_thumb_tag" do
    it "does not embed full blob data in the tag" do
      html = helper.pdf_product_thumb_tag(blob, width: 40, class: "pdf-thumb-sm")

      expect(html).to include("w_40/#{blob.key}")
      expect(html).not_to include("base64")
    end
  end
end
