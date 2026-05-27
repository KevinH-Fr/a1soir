# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductsSeoAi::Prepare do
  let(:csv_path) { Rails.root.join("tmp/test_seo_export.csv") }

  before do
    CSV.open(csv_path, "w", write_headers: true, headers: %w[id handle old_nom couleur taille description]) do |csv|
      csv << [1, "veste-test", "Veste Test", "beige", "44", "Veste costume beige"]
      csv << [2, "veste-test", "Veste Test", "beige", "46", "Veste costume beige"]
      csv << [3, "robe-ada", "Robe Ada", "noir", "38", "Robe longue dentelle"]
    end
  end

  after do
    FileUtils.rm_f(csv_path)
    FileUtils.rm_f(ProductsSeoAi::Paths.families_json)
  end

  it "groups SKUs by handle into families.json" do
    result = described_class.call(csv_path: csv_path)

    expect(result[:family_count]).to eq(2)
    expect(result[:sku_count]).to eq(3)

    data = JSON.parse(File.read(ProductsSeoAi::Paths.families_json))
    families = data["families"]
    veste = families.find { |f| f["handle"] == "veste-test" }

    expect(veste["variant_count"]).to eq(2)
    expect(veste["couleurs"]).to eq(["beige"])
    expect(veste["tailles"]).to eq(%w[44 46])
  end
end
