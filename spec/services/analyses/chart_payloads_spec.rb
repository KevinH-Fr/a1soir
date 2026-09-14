# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analyses::ChartPayloads do
  let(:helper_double) do
    data = {
      :@groupedByDateCa => { "05/03/2026" => 150, "06/03/2026" => 80 },
      :@groupedByDate => { "05/03/2026" => 2, "06/03/2026" => 1 },
      :@groupedByDateArticles => { "05/03/2026" => 3 },
      :@totalPrixCaCb => 10.to_d,
      :@totalPrixCaEspeces => 20.to_d,
      :@totalPrixCaCheque => 0.to_d,
      :@totalPrixCaVirement => 0.to_d,
      :@totalPrixCaStripe => 30.to_d,
      :@totalPrixCa => 60.to_d,
      :@nbLoc => 2,
      :@nbVente => 1,
      :@nbTotalArticles => 3,
      :@totalTransactionsLoc => 100.to_d,
      :@totalTransactionsVente => 50.to_d,
      :@totalTransactions => 150.to_d,
      :@groupedByDateTransactions => { "05/03/2026" => 120 },
      :@stats_par_profile => [
        { profile: "Alice", commandes: 2, devis: 1, ca: 100.to_d, couleur: "rgb(184, 74, 107)",
          ca_by_day: { "05/03/2026" => 80, "06/03/2026" => 20 } },
        { profile: "Bob", commandes: 1, devis: 0, ca: 50.to_d, couleur: "rgb(59, 111, 216)",
          ca_by_day: { "06/03/2026" => 50 } }
      ],
      :@catalog_by_type => [{ label: "Robe", quantite: 4 }],
      :@catalog_by_categorie => [{ label: "cat", quantite: 2 }]
    }
    Object.new.tap do |obj|
      data.each do |key, value|
        obj.instance_variable_set(key, value)
      end
      obj.define_singleton_method(:analyses_donut_amount_label) { |amount| amount.to_s }
      obj.define_singleton_method(:analyses_donut_ht_label) { |amount| amount.to_s }
    end
  end

  subject(:payloads) { described_class.new(helper_double) }

  it "builds mixed timeline with aligned labels" do
    config = payloads.build(:synthese_timeline_mixed)
    expect(config[:data][:labels]).to eq(%w[05/03/2026 06/03/2026])
    expect(config[:data][:datasets].size).to eq(2)
    expect(config[:data][:datasets].first[:type]).to eq("line")
    expect(config[:data][:datasets].second[:type]).to eq("bar")
  end

  it "builds CA timeline line chart" do
    config = payloads.build(:ca_timeline)
    expect(config[:type]).to eq("line")
    expect(config[:data][:labels]).to eq(%w[05/03/2026 06/03/2026])
  end

  it "builds payment modes doughnut with center text metadata" do
    config = payloads.build(:ca_payment_modes_doughnut)
    expect(config[:type]).to eq("doughnut")
    expect(config[:_centerText]).to be_present
    expect(config[:data][:datasets].first[:data]).to eq([10, 20, 0, 0, 30])
  end

  it "builds horizontal CA profiles bar chart" do
    config = payloads.build(:profiles_grouped)
    expect(config[:options][:indexAxis]).to eq("y")
    expect(config[:data][:labels]).to eq(%w[Alice Bob])
    expect(config[:data][:datasets].map { |d| d[:label] }).to eq(["CA (€)"])
    expect(config[:data][:datasets].first[:data]).to eq([100, 50])
  end

  it "builds profiles CA timeline line chart" do
    config = payloads.build(:profiles_ca_timeline)
    expect(config[:type]).to eq("line")
    expect(config[:data][:labels]).to eq(%w[05/03/2026 06/03/2026])
    # Trié par CA décroissant (Alice puis Bob).
    expect(config[:data][:datasets].map { |d| d[:label] }).to eq(%w[Alice Bob])
    expect(config[:data][:datasets].first[:data]).to eq([80, 20])
    # Jour sans CA → nil + spanGaps (pas de plongée à 0).
    expect(config[:data][:datasets].second[:data]).to eq([nil, 50])
    expect(config[:data][:datasets].second[:spanGaps]).to be(true)
    expect(config[:data][:datasets].first[:borderWidth]).to eq(2.5)
  end
end
