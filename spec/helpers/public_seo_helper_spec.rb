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
      expect(helper.public_static_asset_url("images/autourdunsoir_drapeau.png")).to eq(
        "https://a1soir.com/images/autourdunsoir_drapeau.png"
      )
    end

    it "accepts a leading slash" do
      expect(helper.public_static_asset_url("/images/logo.png")).to eq(
        "https://a1soir.com/images/logo.png"
      )
    end
  end
end
