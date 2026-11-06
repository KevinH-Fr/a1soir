# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SEO costume catalogue" do
  let!(:costume) { CategorieProduit.create!(nom: "costume") }
  let!(:smokings) { CategorieProduit.create!(nom: "smokings") }

  it "does not expand period-costume guides onto ceremony categories" do
    page = SeoPages::Registry.find("costumes-epoque-histoire-mode", scope: "guides")

    expect(SeoPages::CategoryScope.call(page)).to be_empty
    expect(page.dig(:product_filters, :catalogue)).to eq("costume_epoque_deguisements")
  end

  it "keeps ceremony suit guides on costume and smokings" do
    page = SeoPages::Registry.find("smoking-ou-costume-mariage", scope: "guides")

    expect(SeoPages::CategoryScope.call(page)).to contain_exactly(costume, smokings)
  end
end
