# frozen_string_literal: true

require "rails_helper"

RSpec.describe SeoPages::CategoryScope do
  let!(:robes_courtes) { CategorieProduit.create!(nom: "robes de mariée courtes") }
  let!(:robes_longues) { CategorieProduit.create!(nom: "robes de mariée longues") }
  let!(:costume) { CategorieProduit.create!(nom: "costume") }
  let!(:smokings) { CategorieProduit.create!(nom: "smokings") }
  let!(:chaussures) { CategorieProduit.create!(nom: "chaussures") }
  let!(:accessoires) { CategorieProduit.create!(nom: "accessoires") }
  let!(:accessoires_femmes) { CategorieProduit.create!(nom: "accessoires femmes") }
  let!(:robes_soiree_courtes) { CategorieProduit.create!(nom: "robes courtes") }
  let!(:robes_soiree_longues) { CategorieProduit.create!(nom: "robes longues") }
  let!(:enfants) { CategorieProduit.create!(nom: "enfants") }

  it "expands wedding guide pages to all wedding dress categories" do
    page = SeoPages::Registry.find("comment-choisir-sa-robe-de-mariee", scope: "guides")

    expect(described_class.call(page)).to contain_exactly(robes_courtes, robes_longues)
  end

  it "keeps explicit categories and expands suit pages" do
    page = SeoPages::Registry.find("smoking-ou-costume-mariage", scope: "guides")

    expect(described_class.call(page)).to contain_exactly(costume, smokings)
  end

  it "includes enfants on costume mariage cannes" do
    page = SeoPages::Registry.find("costume-mariage-cannes", scope: "local")

    expect(described_class.call(page)).to contain_exactly(costume, smokings, enfants)
  end

  it "returns configured categories for local landing pages" do
    page = SeoPages::Registry.find("robe-de-mariee-cannes", scope: "local")

    expect(described_class.call(page)).to contain_exactly(robes_courtes, robes_longues)
  end

  it "keeps only accessory categories on the shoes and accessories guide" do
    page = SeoPages::Registry.find("chaussures-accessoires-soiree", scope: "guides")

    expect(described_class.call(page)).to contain_exactly(chaussures, accessoires, accessoires_femmes)
    expect(described_class.call(page)).not_to include(robes_soiree_courtes, robes_soiree_longues)
  end
end
