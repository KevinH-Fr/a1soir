# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analyses::KpiSnapshot do
  before { AnalysesDashboardDataset.seed! }

  let(:period) { AnalysesDashboardDataset.period_params }

  it "limits computation to requested metrics" do
    snapshot = described_class.call(period, metrics: %i[commandes devis])

    expect(snapshot.keys).to match_array(%i[commandes devis])
    expect(snapshot[:commandes]).to eq(AnalysesDashboardDataset.expected_baseline[:nb_total_commandes])
  end

  it "skips equipe totals when not requested" do
    instance = described_class.new(period, metrics: %i[ca commandes])
    expect(instance).not_to receive(:equipe_totals)
    instance.call
  end

  it "skips DashboardScopes for rdv-only metrics" do
    expect(Analyses::DashboardScopes).not_to receive(:call)

    snapshot = described_class.call(
      period,
      metrics: %i[rdv_demandes_recues rdv_part_cabine rdv_taux_transformation rdv_agenda]
    )

    expect(snapshot.keys).to match_array(
      %i[rdv_demandes_recues rdv_part_cabine rdv_taux_transformation rdv_agenda]
    )
  end
end
