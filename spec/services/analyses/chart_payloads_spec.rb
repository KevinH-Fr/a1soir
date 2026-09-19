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
      :@caLocArticles => 30.to_d,
      :@caVenteArticles => 50.to_d,
      :@totalTransactionsLoc => 100.to_d,
      :@totalTransactionsVente => 50.to_d,
      :@totalTransactions => 150.to_d,
      :@groupedByDateTransactions => { "05/03/2026" => 200, "06/03/2026" => 0 },
      :@groupedByDateCaBoutique => { "05/03/2026" => 100, "06/03/2026" => 50 },
      :@groupedByDateCaEshop => { "05/03/2026" => 50, "06/03/2026" => 30 },
      :@stats_par_profile => [
        { profile: "Alice", commandes: 2, devis: 1, ca: 100.to_d, articles: 3, couleur: "rgb(196, 92, 118)",
          ca_by_day: { "05/03/2026" => 80, "06/03/2026" => 20 } },
        { profile: "Bob", commandes: 1, devis: 0, ca: 50.to_d, articles: 1, couleur: "rgb(74, 132, 176)",
          ca_by_day: { "06/03/2026" => 50 } }
      ],
      :@catalog_by_type => [{ label: "Robe", quantite: 4, ca_lignes: 120.to_d }],
      :@catalog_by_type_by_ca => [{ label: "Robe", quantite: 4, ca_lignes: 120.to_d }],
      :@catalog_by_categorie => [{ label: "cat", quantite: 2, ca_lignes: 50.to_d }],
      :@catalog_by_categorie_by_ca => [{ label: "cat", quantite: 2, ca_lignes: 50.to_d }]
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

  it "builds mixed timeline with aligned labels as bars when ≤2 days" do
    config = payloads.build(:synthese_timeline_mixed)
    expect(config[:data][:labels]).to eq(%w[05/03/2026 06/03/2026])
    expect(config[:data][:datasets].size).to eq(3)
    expect(config[:_grain]).to eq("day")
    ca, cmd, art = config[:data][:datasets]
    expect(ca[:type]).to eq("bar")
    expect(ca[:label]).to eq("CA (€)")
    expect(ca[:maxBarThickness]).to eq(48)
    expect(cmd[:type]).to eq("bar")
    expect(cmd[:label]).to eq("Commandes")
    expect(cmd[:data]).to eq([2, 1])
    expect(art[:type]).to eq("bar")
    expect(art[:label]).to eq("Articles")
    expect(art[:data]).to eq([3, 0])
    expect(art[:yAxisID]).to eq("y1")
  end

  it "builds mixed timeline as line when the day range fills ≥3 labels" do
    helper_double.instance_variable_set(:@datedebut, Date.new(2026, 3, 4))
    helper_double.instance_variable_set(:@datefin, Date.new(2026, 3, 6))
    helper_double.instance_variable_set(:@timeline_grain, :day)

    config = payloads.build(:synthese_timeline_mixed)
    expect(config[:data][:labels]).to eq(%w[04/03/2026 05/03/2026 06/03/2026])
    ca = config[:data][:datasets].first
    expect(ca[:type]).to eq("line")
    expect(ca[:data]).to eq([0, 150, 80])
    expect(ca[:tension]).to eq(0.4)
  end

  it "builds CA + transactions as bars when ≤2 day labels" do
    config = payloads.build(:ca_transactions_timeline)
    expect(config[:type]).to eq("bar")
    expect(config[:_grain]).to eq("day")
    expect(config[:data][:labels]).to eq(%w[05/03/2026 06/03/2026])
    ca, tx = config[:data][:datasets]
    expect(ca[:label]).to eq("CA encaissé (€)")
    expect(ca[:data]).to eq([150, 80])
    expect(ca[:maxBarThickness]).to eq(48)
    expect(tx[:label]).to eq("Transactions (€)")
    expect(tx[:data]).to eq([200, 0])
    expect(config[:options][:scales][:y1]).to be_nil
  end

  it "builds boutique / e-shop channels as bars when ≤2 day labels" do
    config = payloads.build(:ca_channels_timeline)
    expect(config[:type]).to eq("bar")
    expect(config[:_tooltip]).to eq("channels_money")
    expect(config[:_grain]).to eq("day")
    boutique, eshop = config[:data][:datasets]
    expect(boutique[:label]).to eq("Boutique (€)")
    expect(boutique[:data]).to eq([100, 50])
    expect(eshop[:label]).to eq("E-shop (€)")
    expect(eshop[:data]).to eq([50, 30])
    expect(config[:options][:scales][:y][:stacked]).to be_nil
  end

  it "uses bars for boutique / e-shop when only one day has CA" do
    helper_double.instance_variable_set(:@groupedByDateCaBoutique, { "19/09/2026" => 50 })
    helper_double.instance_variable_set(:@groupedByDateCaEshop, {})

    config = payloads.build(:ca_channels_timeline)
    boutique, eshop = config[:data][:datasets]

    expect(config[:type]).to eq("bar")
    expect(config[:data][:labels]).to eq(["19/09/2026"])
    expect(boutique[:data]).to eq([50])
    expect(eshop[:data]).to eq([0])
    expect(boutique[:maxBarThickness]).to eq(48)
  end

  it "builds hourly channels timeline as a line with tension 0" do
    helper_double.instance_variable_set(:@timeline_grain, :hour)
    helper_double.instance_variable_set(:@datedebut, Date.new(2026, 9, 19))
    helper_double.instance_variable_set(:@datefin, Date.new(2026, 9, 19))
    helper_double.instance_variable_set(:@groupedByDateCaBoutique, { "10h" => 40, "14h" => 60 })
    helper_double.instance_variable_set(:@groupedByDateCaEshop, { "11h" => 20 })

    allow(Time).to receive(:zone).and_return(ActiveSupport::TimeZone["Europe/Paris"])
    travel_to Time.zone.local(2026, 9, 19, 16, 0, 0) do
      config = payloads.build(:ca_channels_timeline)
      boutique, eshop = config[:data][:datasets]

      expect(config[:type]).to eq("line")
      expect(config[:_grain]).to eq("hour")
      expect(config[:data][:labels].first).to eq("8h")
      expect(config[:data][:labels]).to include("10h", "11h", "14h")
      expect(config[:data][:labels].last).to eq("16h")
      expect(boutique[:tension]).to eq(0)
      expect(boutique[:pointRadius]).to eq(3)
      expect(boutique[:data][config[:data][:labels].index("10h")]).to eq(40)
      expect(eshop[:data][config[:data][:labels].index("11h")]).to eq(20)
      expect(config[:options][:scales][:x][:ticks][:maxTicksLimit]).to eq(16)
    end
  end

  it "builds CA ratios timeline with panier moyen and articles per commande" do
    config = payloads.build(:ca_ratios_timeline)
    expect(config[:type]).to eq("bar")
    expect(config[:data][:labels]).to eq(%w[05/03/2026 06/03/2026])
    panier, art = config[:data][:datasets]
    expect(panier[:label]).to eq("Panier moyen (€)")
    expect(panier[:data]).to eq([75, 80]) # 150/2, 80/1
    expect(art[:label]).to eq("Art. / commande")
    expect(art[:data]).to eq([1.5, 0.0]) # 3/2, 0 articles le 06
  end

  it "keeps nil panier buckets when there are no commandes (spanGaps)" do
    helper_double.instance_variable_set(:@timeline_grain, :hour)
    helper_double.instance_variable_set(:@datedebut, Date.new(2026, 9, 19))
    helper_double.instance_variable_set(:@datefin, Date.new(2026, 9, 19))
    helper_double.instance_variable_set(:@groupedByDateCa, { "10h" => 100 })
    helper_double.instance_variable_set(:@groupedByDate, { "10h" => 2 })
    helper_double.instance_variable_set(:@groupedByDateArticles, { "10h" => 4 })

    travel_to Time.zone.local(2026, 9, 19, 12, 0, 0) do
      config = payloads.build(:ca_ratios_timeline)
      panier = config[:data][:datasets].first
      idx10 = config[:data][:labels].index("10h")
      idx11 = config[:data][:labels].index("11h")
      expect(panier[:data][idx10]).to eq(50)
      expect(panier[:data][idx11]).to be_nil
      expect(panier[:spanGaps]).to be(true)
    end
  end

  it "builds payment modes doughnut with center text metadata" do
    config = payloads.build(:ca_payment_modes_doughnut)
    expect(config[:type]).to eq("doughnut")
    expect(config[:_centerText]).to be_present
    expect(config[:_tooltip]).to eq("money")
    expect(config[:options][:plugins][:legend][:display]).to eq(true)
    expect(config[:data][:datasets].first[:data]).to eq([10, 20, 0, 0, 30])
  end

  it "builds profiles CA horizontal bars sorted by CA" do
    helper_double.instance_variable_set(
      :@stats_par_profile,
      [
        { profile: "Alice", commandes: 2, devis: 1, ca: 100.to_d, articles: 3, couleur: "rgb(184, 74, 107)" },
        { profile: "Bob", commandes: 1, devis: 0, ca: 50.to_d, articles: 1, couleur: "rgb(59, 111, 216)" },
        { profile: "Carla", commandes: 1, devis: 1, ca: 40.to_d, articles: 1, couleur: "rgb(120, 160, 100)" }
      ]
    )
    config = payloads.build(:profiles_grouped)
    expect(config[:type]).to eq("bar")
    expect(config[:options][:indexAxis]).to eq("y")
    expect(config[:_tooltip]).to eq("money")
    expect(config[:data][:labels]).to eq(%w[Alice Bob Carla])
    expect(config[:data][:datasets].first[:data]).to eq([100, 50, 40])
    expect(config[:data][:datasets].first[:backgroundColor].size).to eq(3)
  end

  it "builds profiles CA + transactions grouped bars" do
    helper_double.instance_variable_set(
      :@stats_par_profile,
      [
        { profile: "Alice", ca: 100.to_d, transactions: 120.to_d },
        { profile: "Bob", ca: 50.to_d, transactions: 40.to_d }
      ]
    )
    config = payloads.build(:profiles_ca_transactions)
    expect(config[:type]).to eq("bar")
    expect(config[:options][:indexAxis]).to eq("y")
    ca, tx = config[:data][:datasets]
    expect(ca[:label]).to eq("CA (€)")
    expect(ca[:data]).to eq([100, 50])
    expect(tx[:label]).to eq("Transactions (€)")
    expect(tx[:data]).to eq([120, 40])
  end

  it "builds profiles CA doughnut with center total" do
    config = payloads.build(:profiles_ca_doughnut)
    expect(config[:type]).to eq("doughnut")
    expect(config[:_tooltip]).to eq("money")
    expect(config[:data][:labels]).to eq(%w[Alice Bob])
    expect(config[:data][:datasets].first[:data]).to eq([100, 50])
    expect(config[:data][:datasets].first[:backgroundColor].size).to eq(2)
    expect(config[:_centerText].first).to include("150")
    expect(config[:_centerText].last).to eq("CA équipe")
  end

  it "builds profiles CA timeline as bars when ≤2 day labels" do
    config = payloads.build(:profiles_ca_timeline)
    expect(config[:type]).to eq("bar")
    expect(config[:_grain]).to eq("day")
    expect(config[:data][:labels]).to eq(%w[05/03/2026 06/03/2026])
    expect(config[:data][:datasets].map { |d| d[:label] }).to eq(%w[Alice Bob])
    expect(config[:data][:datasets].first[:data]).to eq([80, 20])
    expect(config[:data][:datasets].second[:data]).to eq([nil, 50])
    expect(config[:data][:datasets].second[:spanGaps]).to be(true)
  end

  it "builds catalog single-axis quantity bars" do
    config = payloads.build(:catalog_types_bars)
    expect(config[:type]).to eq("bar")
    expect(config[:options][:indexAxis]).to eq("y")
    expect(config[:data][:datasets].size).to eq(1)
    qty = config[:data][:datasets].first
    expect(qty[:label]).to eq("Quantité")
    expect(qty[:data]).to eq([4])
    expect(config[:_tooltip]).to eq("integer")
  end

  it "builds catalog single-axis CA bars from CA-ranked rows" do
    helper_double.instance_variable_set(
      :@catalog_by_type_by_ca,
      [{ label: "Costume", quantite: 1, ca_lignes: 200.to_d }]
    )
    config = payloads.build(:catalog_types_bars_ca)
    expect(config[:data][:labels]).to eq(["Costume"])
    ca = config[:data][:datasets].first
    expect(ca[:label]).to eq("CA (€)")
    expect(ca[:data]).to eq([200])
    expect(config[:_tooltip]).to eq("money")
  end

  it "builds loc/vente quantity doughnut" do
    config = payloads.build(:locvente_qty_doughnut)
    expect(config[:type]).to eq("doughnut")
    expect(config[:_tooltip]).to eq("locvente_qty")
    expect(config[:data][:labels]).to eq(%w[Location Vente])
    expect(config[:data][:datasets].size).to eq(1)
    expect(config[:data][:datasets].first[:data]).to eq([2, 1])
    expect(config[:_centerText]).to include("3", "qté articles")
  end

  it "builds articles loc/vente CA doughnut" do
    config = payloads.build(:articles_locvente_ca_doughnut)
    expect(config[:type]).to eq("doughnut")
    expect(config[:_tooltip]).to eq("locvente_money")
    expect(config[:data][:datasets].first[:data]).to eq([30, 50])
    expect(config[:_centerText].first).to include("80")
  end

  it "builds transactions loc/vente euro doughnut" do
    config = payloads.build(:transactions_euro_doughnut)
    expect(config[:type]).to eq("doughnut")
    expect(config[:_tooltip]).to eq("locvente_money")
    expect(config[:data][:datasets].first[:data]).to eq([100, 50])
    expect(config[:_centerText].first).to include("150")
  end

end
