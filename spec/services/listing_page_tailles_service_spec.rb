# frozen_string_literal: true

require "rails_helper"

RSpec.describe ListingPageTaillesService do
  let!(:taille_s) { Taille.create!(nom: "S") }
  let!(:taille_m) { Taille.create!(nom: "M") }
  let!(:couleur) { Couleur.create!(nom: "noir") }

  let!(:produit_s) do
    Produit.create!(
      nom: "Robe pastilles",
      prixvente: 50,
      stripe_price_id: "price_listing_tailles_s",
      eshop: true,
      today_availability: true,
      quantite: 1,
      taille: taille_s,
      couleur: couleur,
      actif: true
    )
  end

  let!(:produit_m) do
    Produit.create!(
      nom: "Robe pastilles",
      prixvente: 50,
      stripe_price_id: "price_listing_tailles_m",
      eshop: true,
      today_availability: true,
      quantite: 1,
      taille: taille_m,
      couleur: couleur,
      actif: true
    )
  end

  let(:key) { [produit_s.handle, couleur.id] }

  it "returns available sizes for the listed family on the current page" do
    result = described_class.new([produit_s]).call

    expect(result[key].map { |entry| entry[:nom] }).to eq(%w[M S])
    expect(result[key].map { |entry| entry[:id] }).to contain_exactly(produit_s.id, produit_m.id)
  end

  it "still returns a single size when the family has only one size" do
    Produit.where(id: produit_m.id).update_all(today_availability: false)

    result = described_class.new([produit_s.reload]).call
    expect(result[key].map { |entry| entry[:nom] }).to eq(%w[S])
    expect(result[key].first[:id]).to eq(produit_s.id)
  end

  it "keeps only the filtered size when a taille filter is active" do
    result = described_class.new([produit_s], taille_filter_id: taille_s.id).call

    expect(result[key].map { |entry| entry[:nom] }).to eq(%w[S])
    expect(result[key].first[:id]).to eq(produit_s.id)
  end

  it "ignores siblings of another colour" do
    autre_couleur = Couleur.create!(nom: "blanc")
    Produit.create!(
      nom: "Robe pastilles",
      prixvente: 50,
      stripe_price_id: "price_listing_tailles_blanc",
      eshop: true,
      today_availability: true,
      quantite: 1,
      taille: taille_m,
      couleur: autre_couleur,
      actif: true
    )

    result = described_class.new([produit_s]).call
    expect(result[key].map { |entry| entry[:nom] }).to eq(%w[M S])
  end
end
