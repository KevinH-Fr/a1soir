# frozen_string_literal: true

require "rails_helper"

RSpec.describe Analyses::TimelineBuckets do
  around do |example|
    Time.use_zone("Europe/Paris") { example.run }
  end

  describe ".grain" do
    it "returns :hour for a single calendar day" do
      day = Date.new(2026, 9, 19)
      expect(described_class.grain(day, day)).to eq(:hour)
    end

    it "returns :day when the range spans two or more days" do
      expect(described_class.grain(Date.new(2026, 9, 18), Date.new(2026, 9, 19))).to eq(:day)
    end

    it "returns :day when dates are blank" do
      expect(described_class.grain(nil, nil)).to eq(:day)
    end
  end

  describe ".hour_label" do
    it "uses Paris local hour (UTC 09:30 → 11h)" do
      utc = Time.utc(2026, 9, 19, 9, 30, 0)
      expect(described_class.hour_label(utc)).to eq("11h")
    end
  end

  describe ".group_times" do
    it "buckets amounts by Paris hour" do
      rows = [
        [Time.utc(2026, 9, 19, 8, 0, 0), 10],   # 10h Paris
        [Time.utc(2026, 9, 19, 8, 45, 0), 5],   # 10h Paris
        [Time.utc(2026, 9, 19, 14, 0, 0), 20]  # 16h Paris
      ]
      expect(described_class.group_times(rows, grain: :hour)).to eq(
        "10h" => 15.to_d,
        "16h" => 20.to_d
      )
    end

    it "buckets amounts by day label" do
      rows = [
        [Time.zone.local(2026, 9, 18, 10), 10],
        [Time.zone.local(2026, 9, 19, 16), 20]
      ]
      expect(described_class.group_times(rows, grain: :day)).to eq(
        "18/09/2026" => 10.to_d,
        "19/09/2026" => 20.to_d
      )
    end
  end

  describe ".filled_labels" do
    it "fills every day in the range" do
      labels = described_class.filled_labels(
        debut: Date.new(2026, 9, 17),
        fin: Date.new(2026, 9, 19),
        grain: :day,
        data_keys: ["19/09/2026"]
      )
      expect(labels).to eq(%w[17/09/2026 18/09/2026 19/09/2026])
    end

    it "fills hours from 8h to now on today without future hours" do
      now = Time.zone.local(2026, 9, 19, 14, 20, 0)
      labels = described_class.filled_labels(
        debut: Date.new(2026, 9, 19),
        fin: Date.new(2026, 9, 19),
        grain: :hour,
        data_keys: ["11h"],
        now: now
      )
      expect(labels.first).to eq("8h")
      expect(labels.last).to eq("14h")
      expect(labels).to include("11h")
      expect(labels).not_to include("15h")
    end

    it "extends the hour range when data falls outside 8h–20h" do
      labels = described_class.filled_labels(
        debut: Date.new(2026, 9, 18),
        fin: Date.new(2026, 9, 18),
        grain: :hour,
        data_keys: %w[6h 22h],
        now: Time.zone.local(2026, 9, 19, 12)
      )
      expect(labels.first).to eq("6h")
      expect(labels.last).to eq("22h")
    end

    it "sorts existing keys when dates are blank (day grain)" do
      labels = described_class.filled_labels(
        debut: nil,
        fin: nil,
        grain: :day,
        data_keys: %w[06/03/2026 05/03/2026]
      )
      expect(labels).to eq(%w[05/03/2026 06/03/2026])
    end
  end
end
