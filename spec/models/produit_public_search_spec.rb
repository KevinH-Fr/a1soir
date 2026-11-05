# frozen_string_literal: true

require "rails_helper"

RSpec.describe Produit, ".matching_public_search" do
  before { allow(GenerateQr).to receive(:call) }

  let!(:robe) { Produit.create!(nom: "Robé") }
  let!(:soiree) { Produit.create!(nom: "Soirée robe", description: "pour une fête") }
  let!(:rose) { Produit.create!(nom: "Robe longue", couleur: Couleur.create!(nom: "Rose")) }
  let!(:ceremonie) do
    produit = Produit.create!(nom: "Ensemble blanc")
    produit.categorie_produits << CategorieProduit.create!(nom: "Cérémonie")
    produit
  end
  let!(:soie) { Produit.create!(nom: "100% soie") }
  let!(:smoking) { Produit.create!(nom: "Smoking noir") }
  let!(:coeur) { Produit.create!(nom: "Cœur") }

  def found_by(term)
    Produit.matching_public_search(term).pluck(:id)
  end

  it "matches e and é in both directions on the name" do
    expect(found_by("robe")).to include(robe.id)
    expect(found_by("robé")).to include(robe.id)
    expect(found_by("coeur")).to include(coeur.id)
  end

  it "matches an accented category name without the accent" do
    expect(found_by("ceremonie")).to contain_exactly(ceremonie.id)
  end

  it "matches every word regardless of order" do
    expect(found_by("robe soiree")).to include(soiree.id)
    expect(found_by("soiree robe")).to include(soiree.id)
    expect(found_by("robe rose")).to include(rose.id)
    expect(found_by("rose robe")).to include(rose.id)
  end

  it "excludes a product when one word is missing" do
    expect(found_by("robe chapeau")).not_to include(soiree.id, robe.id, rose.id)
  end

  it "excludes an unrelated product" do
    expect(found_by("robe")).not_to include(smoking.id)
  end

  it "treats % as a literal character" do
    expect(found_by("100%")).to contain_exactly(soie.id)
  end

  it "returns the current scope when the term is blank" do
    expect(Produit.where(id: smoking.id).matching_public_search("  ").pluck(:id)).to eq([smoking.id])
  end

  it "keeps filters already applied on the relation" do
    expect(Produit.where(id: smoking.id).matching_public_search("robe")).to be_empty
    expect(Produit.where(id: robe.id).matching_public_search("robe").pluck(:id)).to eq([robe.id])
  end
end
