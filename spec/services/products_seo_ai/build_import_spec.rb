# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductsSeoAi::BuildImport do
  let(:output_path) { Rails.root.join("tmp/test_seo_import_out.csv") }

  before do
    ProductsSeoAi::Paths.ensure_dirs!
    File.write(
      ProductsSeoAi::Paths.families_json,
      {
        families: [
          {
            handle: "veste-test",
            skus: [
              { id: "1", old_nom: "Veste Test" },
              { id: "2", old_nom: "Veste Test" }
            ]
          }
        ]
      }.to_json
    )

    File.write(
      ProductsSeoAi::Paths.batch_file(1),
      {
        batch_index: 1,
        items: [
          { handle: "veste-test", new_nom: "Veste costume beige", approved: true, notes: "" }
        ]
      }.to_json
    )
  end

  after do
    FileUtils.rm_rf(ProductsSeoAi::Paths.root)
    FileUtils.rm_f(output_path)
  end

  it "expands family titles to one row per SKU" do
    result = described_class.call(output_path: output_path)

    rows = CSV.read(output_path, headers: true)
    expect(rows.size).to eq(2)
    expect(rows.map { |r| r["new_nom"] }.uniq).to eq(["Veste costume beige"])
    expect(rows.map { |r| r["approved"] }.uniq).to eq(["yes"])
    expect(result[:row_count]).to eq(2)
  end
end
