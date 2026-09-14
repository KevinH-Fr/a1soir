# frozen_string_literal: true

# Specs de visibilité des sections Analyses (onglets + filtres épinglés).
require "rails_helper"

RSpec.describe Analyses::DashboardVisibility do
  subject(:visibility) do
    described_class.new(
      { filter_type_produit: "3", filter_locvente: "location" },
      ca_mode: :paiements,
      vue: "catalogue"
    )
  end

  it "normalizes unknown vue to synthese" do
    expect(described_class.normalize_vue("invalid")).to eq("synthese")
  end

  it "detects pinned dimensions" do
    expect(visibility.dimension_pinned?(:type_produit)).to be(true)
    expect(visibility.dimension_pinned?(:locvente)).to be(true)
    expect(visibility.dimension_pinned?(:categorie)).to be(false)
  end

  it "hides catalog type chart when type is pinned" do
    expect(visibility.show?(:catalog_by_type)).to be(false)
    expect(visibility.show?(:catalog_by_categorie)).to be(true)
  end

  it "shows KPI on every analyses vue" do
    expect(described_class.new({}, ca_mode: :paiements, vue: "synthese").show?(:kpi)).to be(true)
    expect(described_class.new({}, ca_mode: :paiements, vue: "ca").show?(:kpi)).to be(true)
    expect(visibility.show?(:kpi)).to be(true)
    expect(described_class.new({}, ca_mode: :paiements, vue: "equipe").show?(:kpi)).to be(true)
  end

  it "shows CA section charts on ca vue only" do
    ca = described_class.new({}, ca_mode: :paiements, vue: "ca")
    synth = described_class.new({}, ca_mode: :paiements, vue: "synthese")
    expect(ca.show?(:ca_section)).to be(true)
    expect(synth.show?(:ca_section)).to be(false)
  end
end
