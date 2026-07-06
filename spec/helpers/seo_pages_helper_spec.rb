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

  describe "#seo_footer_pages" do
    it "returns pages for a footer group in order" do
      pages = helper.seo_footer_pages("bride")

      expect(pages.map { |p| p[:slug] }).to eq(%w[
        robe-de-mariee-cannes
        essayage-robe-de-mariee-cannes
        comment-choisir-sa-robe-de-mariee
        robe-de-mariee-morphologie
      ])
    end
  end

  describe "#seo_footer_groups" do
    it "returns themed footer groups with curated pages" do
      groups = helper.seo_footer_groups

      expect(groups.map(&:first)).to eq(%w[bride guest costume])
      expect(groups.assoc("guest").last.map { |p| p[:slug] }).to eq(%w[
        robe-invitee-mariage
        tenue-gala-ceremonie
        achat-ou-location-tenue-soiree
      ])
      expect(groups.assoc("costume").last.map { |p| p[:slug] }).to eq(%w[
        costume-mariage-cannes
        smoking-ou-costume-mariage
        location-smoking-costume-cannes
        chaussures-accessoires-soiree
      ])
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
