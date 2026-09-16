# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analyses::KpiTrends do
  describe "trend math" do
    it "computes signed percentage change" do
      trends = described_class.new(
        filter_params: { debut: "2026-03-10", fin: "2026-03-11" },
        vue: "synthese"
      )
      trend = trends.send(:build_trend, 150, 100, "vs 2 j. préc.")

      expect(trend[:signed_pct]).to eq(50.0)
      expect(trend[:direction]).to eq(:up)
      expect(trend[:pct]).to eq(50.0)
    end

    it "returns neutral when previous is zero" do
      trends = described_class.new(
        filter_params: { debut: "2026-03-10", fin: "2026-03-11" },
        vue: "synthese"
      )
      trend = trends.send(:build_trend, 10, 0, "vs veille")

      expect(trend[:pct]).to be_nil
      expect(trend[:direction]).to eq(:neutral)
    end
  end

  describe ".call with current metrics" do
    it "reuses provided current values and only snapshots the comparison period" do
      current = {
        ca: 200,
        commandes: 4,
        articles_lignes: 8,
        top_vendeur_ca: 120,
        top_vendeur_profile_id: 42
      }
      reference = { ca: 100, commandes: 2, articles_lignes: 4, top_vendeur_ca: 80 }

      expect(Analyses::KpiSnapshot).to receive(:call).once do |params, metrics:|
        expect(params[:debut]).to eq(Date.new(2026, 3, 8))
        expect(params[:fin]).to eq(Date.new(2026, 3, 9))
        expect(params[:top_vendeur_profile_id]).to eq(42)
        expect(metrics).to eq(%i[ca commandes articles_lignes top_vendeur_ca])
        reference
      end

      result = described_class.call(
        filter_params: { debut: "2026-03-10", fin: "2026-03-11" },
        vue: "synthese",
        current: current
      )

      expect(result[:period_label]).to eq("vs 2 j. préc.")
      expect(result[:trends][:ca][:signed_pct]).to eq(100.0)
      expect(result[:trends][:commandes][:signed_pct]).to eq(100.0)
      expect(result[:trends][:top_vendeur_ca][:signed_pct]).to eq(50.0)
      expect(result[:trends]).not_to have_key(:devis)
    end

    it "computes equipe trends including top vendeur CA" do
      current = {
        equipe_ca: 300,
        equipe_commandes: 6,
        equipe_devis: 4,
        top_vendeur_ca: 180,
        top_vendeur_profile_id: 7
      }
      reference = {
        equipe_ca: 200,
        equipe_commandes: 4,
        equipe_devis: 2,
        top_vendeur_ca: 120
      }

      expect(Analyses::KpiSnapshot).to receive(:call).once do |params, metrics:|
        expect(params[:top_vendeur_profile_id]).to eq(7)
        expect(metrics).to eq(%i[equipe_ca equipe_commandes equipe_devis top_vendeur_ca])
        reference
      end

      result = described_class.call(
        filter_params: { debut: "2026-03-10", fin: "2026-03-11" },
        vue: "equipe",
        current: current
      )

      expect(result[:trends][:equipe_devis][:signed_pct]).to eq(100.0)
      expect(result[:trends][:top_vendeur_ca][:signed_pct]).to eq(50.0)
    end
  end
end
