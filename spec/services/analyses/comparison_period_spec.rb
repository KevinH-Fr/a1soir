# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analyses::ComparisonPeriod do
  it "returns the previous window of equal length" do
    range = described_class.previous_range(Date.new(2026, 3, 10), Date.new(2026, 3, 19))

    expect(range[:debut]).to eq(Date.new(2026, 2, 28))
    expect(range[:fin]).to eq(Date.new(2026, 3, 9))
    expect(range[:label]).to eq("vs 10 j. préc.")
  end

  it "labels single-day comparison as veille" do
    range = described_class.previous_range(Date.new(2026, 3, 15), Date.new(2026, 3, 15))

    expect(range[:debut]).to eq(Date.new(2026, 3, 14))
    expect(range[:fin]).to eq(Date.new(2026, 3, 14))
    expect(range[:label]).to eq("vs veille")
  end
end
