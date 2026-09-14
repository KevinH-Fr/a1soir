# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analyses::KpiTrends do
  describe "trend math" do
    it "computes signed percentage change" do
      trends = described_class.new(filter_params: { debut: "2026-03-10", fin: "2026-03-11", vue: "synthese" })
      trend = trends.send(:build_trend, 150, 100, "vs 2 j. préc.")

      expect(trend[:signed_pct]).to eq(50.0)
      expect(trend[:direction]).to eq(:up)
      expect(trend[:pct]).to eq(50.0)
    end

    it "returns neutral when previous is zero" do
      trends = described_class.new(filter_params: { debut: "2026-03-10", fin: "2026-03-11", vue: "synthese" })
      trend = trends.send(:build_trend, 10, 0, "vs veille")

      expect(trend[:pct]).to be_nil
      expect(trend[:direction]).to eq(:neutral)
    end
  end
end
