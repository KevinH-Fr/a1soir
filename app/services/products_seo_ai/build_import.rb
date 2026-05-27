# frozen_string_literal: true

require "csv"
require "json"

module ProductsSeoAi
  class BuildImport
    IMPORT_HEADERS = %w[id handle old_nom new_nom approved notes].freeze

    def self.call(output_path: nil)
      new(output_path: output_path).call
    end

    def initialize(output_path: nil)
      @output_path = Pathname.new(output_path || Config.import_csv)
      @output_path = Rails.root.join(@output_path) unless @output_path.absolute?
    end

    def call
      abort "Fichier familles introuvable." unless Paths.families_json.exist?

      data = JSON.parse(File.read(Paths.families_json))
      families = data["families"] || []
      ai_results = load_all_batch_items

      rows = []
      missing_handles = []

      families.each do |family|
        handle = family["handle"]
        result = ai_results[handle]

        unless result
          missing_handles << handle
          next
        end

        approved = result["approved"] ? "yes" : ""
        new_nom = result["new_nom"]
        notes = result["notes"]

        family["skus"].each do |sku|
          rows << [
            sku["id"],
            handle,
            sku["old_nom"],
            new_nom,
            approved,
            notes
          ]
        end
      end

      csv_content = CSV.generate(write_headers: true, headers: IMPORT_HEADERS) do |csv|
        rows.sort_by { |r| r[0].to_i }.each { |row| csv << row }
      end

      File.write(@output_path, csv_content)

      {
        output_path: @output_path,
        row_count: rows.size,
        missing_handles: missing_handles
      }
    end

    private

    def load_all_batch_items
      results = {}

      batch_files = Dir.glob(Paths.batches_dir.join("*.json")).sort
      abort "Aucun batch dans #{Paths.batches_dir}. Lancez products:seo_ai_generate." if batch_files.empty?

      batch_files.each do |path|
        payload = JSON.parse(File.read(path))
        (payload["items"] || []).each do |item|
          handle = item["handle"].to_s.strip
          next if handle.blank?

          results[handle] = item
        end
      end

      results
    end
  end
end
