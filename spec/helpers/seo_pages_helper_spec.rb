# frozen_string_literal: true

require "rails_helper"

RSpec.describe SeoPagesHelper, type: :helper do
  describe "#seo_page_html" do
    it "adds seo-page-link class to anchor tags" do
      html = '<p>See our <a href="/fr/guides/test">guide</a>.</p>'
      result = helper.seo_page_html(html)

      expect(result).to include('class="seo-page-link"')
      expect(result).to include('href="/fr/guides/test"')
    end

    it "returns empty string for blank input" do
      expect(helper.seo_page_html(nil)).to eq("")
    end
  end

  describe "#seo_page_faq_schema" do
    let(:page) { SeoPages::Registry.find("robe-de-mariee-cannes", scope: "local") }

    it "returns FAQPage schema when FAQ items exist" do
      schema = helper.seo_page_faq_schema(page)

      expect(schema["@type"]).to eq("FAQPage")
      expect(schema["mainEntity"].length).to be >= 3
      expect(schema["mainEntity"].first).to include(
        "@type" => "Question",
        "name" => kind_of(String),
        "acceptedAnswer" => include("@type" => "Answer", "text" => kind_of(String))
      )
    end

    it "returns nil when there are no FAQ items" do
      page = { slug: "test-no-faq" }
      allow(helper).to receive(:seo_page_faq_items).with(page).and_return([])

      expect(helper.seo_page_faq_schema(page)).to be_nil
    end
  end
end
