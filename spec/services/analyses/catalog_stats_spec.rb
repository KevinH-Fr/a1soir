# frozen_string_literal: true

# Specs CatalogStats : top produits et attribution d'une seule catégorie par produit.
require "rails_helper"

RSpec.describe Analyses::CatalogStats do
  let(:type_a) { TypeProduit.create!(nom: "Type A #{SecureRandom.hex(2)}") }
  let(:type_b) { TypeProduit.create!(nom: "Type B #{SecureRandom.hex(2)}") }
  let(:cat_zzz) { CategorieProduit.create!(nom: "Zebra cat") }
  let(:cat_aaa) { CategorieProduit.create!(nom: "Alpha cat") }

  let(:produit_multi) do
    p = Produit.create!(nom: "Multi", prixvente: 10, quantite: 3, type_produit: type_a)
    p.categorie_produits << [cat_zzz, cat_aaa]
    p
  end

  let(:produit_solo) do
    Produit.create!(nom: "Solo", prixvente: 20, quantite: 2, type_produit: type_b)
  end

  let(:client) do
    Client.create!(
      nom: "Cat",
      prenom: "Stats",
      propart: "particulier",
      intitule: Client::INTITULE_OPTIONS.first,
      mail: "catalog-#{SecureRandom.hex(4)}@test.com"
    )
  end

  let(:profile) { Profile.create!(prenom: "V", nom: "Stats") }

  let!(:commande) do
    Commande.create!(
      client: client,
      profile: profile,
      nom: "Cmd",
      montant: 50,
      devis: false,
      type_locvente: "vente"
    )
  end

  before do
    Article.create!(commande: commande, produit: produit_multi, quantite: 2, prix: 30, total: 30, locvente: "vente")
    Article.create!(commande: commande, produit: produit_solo, quantite: 1, prix: 20, total: 20, locvente: "vente")
  end

  let(:articles_scope) { Article.joins(:commande).merge(Commande.hors_devis).where(commande_id: commande.id) }

  subject(:result) { described_class.call(articles_scope) }

  it "ranks top products by quantity then CA" do
    expect(result[:top_products].map { |r| r[:produit].id }).to eq([produit_multi.id, produit_solo.id])
    expect(result[:top_products].first[:quantite]).to eq(2)
    expect(result[:top_products].first[:ca_lignes]).to eq(30.to_d)
  end

  it "rolls up by type without duplication" do
    by_type = result[:by_type].index_by { |r| r[:label] }
    expect(by_type[type_a.nom][:quantite]).to eq(2)
    expect(by_type[type_b.nom][:quantite]).to eq(1)
  end

  it "attributes multi-category products to the first category by name" do
    by_cat = result[:by_categorie].index_by { |r| r[:label] }
    expect(by_cat["alpha cat"][:quantite]).to eq(2)
    expect(by_cat.key?("zebra cat")).to be(false)
    expect(result[:categorie_attribution_notice]).to include("première")
  end

  it "merges stripe e-shop quantities into catalog aggregates" do
    eshop_cmd = Commande.create!(
      client: client,
      profile: Profile.for_eshop_commandes,
      nom: "Eshop cat",
      montant: 50,
      devis: false,
      type_locvente: "vente",
      eshop: true
    )
    payment = StripePayment.create!(
      commande: eshop_cmd,
      stripe_payment_id: "pi_cat_#{SecureRandom.hex(4)}",
      amount: 5000,
      currency: "eur",
      status: "paid"
    )
    StripePaymentItem.create!(
      stripe_payment: payment,
      produit: produit_solo,
      quantity: 4,
      unit_amount: 1250
    )

    stripe_scope = StripePaymentItem.joins(:stripe_payment).where(stripe_payments: { commande_id: eshop_cmd.id })
    merged = described_class.call(articles_scope, stripe_items_scope: stripe_scope)

    solo = merged[:top_products].find { |r| r[:produit].id == produit_solo.id }
    expect(solo[:quantite]).to eq(5) # 1 article + 4 stripe
    expect(solo[:ca_lignes]).to eq(70.to_d) # 20 + 50
  end
end
