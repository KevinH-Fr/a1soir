# frozen_string_literal: true

require "rails_helper"

RSpec.describe PublicSeoHelper, type: :helper do
  describe "#public_static_asset_url" do
    before do
      allow(helper).to receive(:request).and_return(
        instance_double(ActionDispatch::Request, base_url: "https://a1soir.com")
      )
    end

    it "builds an absolute path without locale query string" do
      expect(helper.public_static_asset_url("images/logo_Autour_d_un_soir.png")).to eq(
        "https://a1soir.com/images/logo_Autour_d_un_soir.png"
      )
    end

    it "accepts a leading slash" do
      expect(helper.public_static_asset_url("/images/logo.png")).to eq(
        "https://a1soir.com/images/logo.png"
      )
    end
  end

  describe "#structured_store_logo_url" do
    before do
      allow(helper).to receive(:request).and_return(
        instance_double(ActionDispatch::Request, base_url: "https://a1soir.com")
      )
    end

    it "points at the brand wordmark" do
      expect(helper.structured_store_logo_url).to eq(
        "https://a1soir.com/images/logo_Autour_d_un_soir.png"
      )
    end
  end

  describe "#default_og_image_url" do
    before do
      allow(helper).to receive(:request).and_return(
        instance_double(ActionDispatch::Request, base_url: "https://a1soir.com")
      )
    end

    it "points at the wide share image" do
      expect(helper.default_og_image_url).to eq(
        "https://a1soir.com/images/autour_d_un_soir_og.png"
      )
    end
  end
end
