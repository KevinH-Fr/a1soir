# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analyses::LineMetrics do
  let(:client) do
    Client.create!(
      nom: "Line",
      prenom: "Metrics",
      propart: "particulier",
      intitule: Client::INTITULE_OPTIONS.first,
      mail: "line-metrics-#{SecureRandom.hex(4)}@test.com"
    )
  end
  let(:profile) { Profile.create!(prenom: "L", nom: "M") }
  let(:produit) { Produit.create!(nom: "P", prixvente: 50, quantite: 3) }

  let!(:boutique) do
    Commande.create!(
      client: client,
      profile: profile,
      nom: "Boutique",
      montant: 50,
      devis: false,
      type_locvente: "vente",
      eshop: false
    )
  end

  let!(:eshop) do
    Commande.create!(
      client: client,
      profile: Profile.for_eshop_commandes,
      nom: "Eshop",
      montant: 80,
      devis: false,
      type_locvente: "vente",
      eshop: true
    )
  end

  before do
    Article.create!(commande: boutique, produit: produit, quantite: 2, prix: 40, total: 40, locvente: "vente")
    Article.create!(commande: boutique, produit: produit, quantite: 1, prix: 30, total: 30, locvente: "location")
    # Ligne article e-shop (ne doit PAS être comptée — source de vérité = Stripe)
    Article.create!(commande: eshop, produit: produit, quantite: 9, prix: 999, total: 999, locvente: "vente")

    payment = StripePayment.create!(
      commande: eshop,
      stripe_payment_id: "pi_line_#{SecureRandom.hex(4)}",
      amount: 8000,
      currency: "eur",
      status: "paid"
    )
    StripePaymentItem.create!(stripe_payment: payment, produit: produit, quantity: 3, unit_amount: 2500)
  end

  let(:articles) { Article.joins(:commande).where(commande_id: [boutique.id, eshop.id]) }
  let(:stripe_items) { StripePaymentItem.joins(:stripe_payment).where(stripe_payments: { commande_id: eshop.id }) }

  subject(:metrics) do
    described_class.new(articles_scope: articles, stripe_items_scope: stripe_items)
  end

  it "counts boutique article lines + stripe lines, ignoring eshop articles" do
    expect(metrics.lignes_count).to eq(3) # 2 boutique + 1 stripe
    expect(metrics.vente_lignes_count).to eq(2) # 1 boutique vente + 1 stripe
    expect(metrics.loc_lignes_count).to eq(1)
    expect(metrics.quantites).to eq(6) # 2+1 boutique + 3 stripe
    expect(metrics.ca_lignes).to eq(145.to_d) # 40+30 + (3*25)
    expect(metrics.loc_ca_lignes).to eq(30.to_d)
    expect(metrics.vente_ca_lignes).to eq(115.to_d) # 40 + 75
  end

  it "aggregates loc / vente quantities per product" do
    agg = metrics.aggregate_by_produit
    expect(agg[:qte_loc][produit.id]).to eq(1)
    expect(agg[:qte_vente][produit.id]).to eq(5) # 2 boutique vente + 3 stripe
  end

  it "does not double-count when stripe scope is empty" do
    empty = described_class.new(articles_scope: articles, stripe_items_scope: StripePaymentItem.none)
    expect(empty.lignes_count).to eq(2)
    expect(empty.ca_lignes).to eq(70.to_d)
  end
end
