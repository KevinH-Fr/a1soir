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

  describe "#cloudinary_attachment_image" do
    it "keeps the HTML width attribute for layout" do
      blob = instance_double(ActiveStorage::Blob, key: "thumb-key")

      html = helper.cloudinary_attachment_image(blob, width: 200, alt: "Robe")

      expect(html).to include('width="200"')
      expect(html).to include("q_auto,f_auto,w_200/thumb-key")
    end
  end

  describe "#cloudinary_video_url" do
    it "returns a transformed Cloudinary URL for an attachment" do
      blob = instance_double(ActiveStorage::Blob, key: "demo-video-key")
      attachment = double("video_attachment", blob: blob)

      expect(helper.cloudinary_video_url(attachment, width: 800)).to eq(
        "https://res.cloudinary.com/dukne3lhz/video/upload/q_auto,w_800,vc_auto,f_mp4/demo-video-key"
      )
    end

    it "accepts a static public_id" do
      expect(helper.cloudinary_video_url("video2_rgzof7", width: 800)).to eq(
        "https://res.cloudinary.com/dukne3lhz/video/upload/q_auto,w_800,vc_auto,f_mp4/video2_rgzof7"
      )
    end

    it "strips a media extension from a public_id" do
      expect(helper.cloudinary_video_url("clip.mp4", width: 1200)).to end_with("/clip")
    end

    it "defaults to mp4 for Safari / iOS HTML5 video" do
      expect(helper.cloudinary_video_url("reel", width: 800)).to include("f_mp4/reel")
    end
  end

  describe "#cloudinary_video_poster_url" do
    it "returns a still frame from the video, not the product image" do
      blob = instance_double(ActiveStorage::Blob, key: "demo-video-key")
      attachment = double("video_attachment", blob: blob)

      expect(helper.cloudinary_video_poster_url(attachment, width: 200, height: 200)).to eq(
        "https://res.cloudinary.com/dukne3lhz/video/upload/so_0,w_200,h_200,c_fill,q_auto,f_jpg/demo-video-key.jpg"
      )
    end
  end

  describe "PagesHelper#collection_card_image_source" do
    it "returns a Cloudinary URL for ActiveStorage attachments" do
      blob = instance_double(ActiveStorage::Blob, key: "card-key-1")
      attachment = double("attachment", attached?: true, blob: blob)

      expect(helper.collection_card_image_source(attachment, width: 800)).to include("w_800/card-key-1")
    end

    it "returns a local path for static assets" do
      expect(helper.collection_card_image_source("/images/cat_costume.webp")).to eq("/images/cat_costume.webp")
    end
  end
end
