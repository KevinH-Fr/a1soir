# frozen_string_literal: true

require "csv"
require "json"

module ProductsSeoAi
  class Prepare
    def self.call(csv_path:)
      new(csv_path: csv_path).call
    end

    def initialize(csv_path:)
      @csv_path = Pathname.new(csv_path)
    end

    def call
      abort "CSV introuvable : #{@csv_path}" unless @csv_path.exist?

      rows = CSV.read(@csv_path, headers: true)
      families_by_handle = {}

      rows.each do |row|
        handle = row["handle"].to_s.strip
        next if handle.blank?

        families_by_handle[handle] ||= {
          "handle" => handle,
          "old_nom" => row["old_nom"].to_s.strip,
          "description" => row["description"].to_s.strip,
          "couleurs" => [],
          "tailles" => [],
          "skus" => []
        }

        family = families_by_handle[handle]
        couleur = row["couleur"].to_s.strip
        taille = row["taille"].to_s.strip

        family["couleurs"] << couleur if couleur.present?
        family["tailles"] << taille if taille.present?

        if family["description"].blank? && row["description"].to_s.strip.present?
          family["description"] = row["description"].to_s.strip
        end

        family["skus"] << {
          "id" => row["id"].to_s.strip,
          "old_nom" => row["old_nom"].to_s.strip,
          "couleur" => couleur,
          "taille" => taille,
          "description" => row["description"].to_s.strip
        }
      end

      families = families_by_handle.values.sort_by { |f| f["handle"] }

      families.each do |family|
        family["couleurs"] = family["couleurs"].uniq.sort
        family["tailles"] = family["tailles"].uniq.sort
        family["variant_count"] = family["skus"].size
        family["sample_ids"] = family["skus"].first(3).map { |s| s["id"] }
      end

      Paths.ensure_dirs!
      File.write(Paths.families_json, JSON.pretty_generate(
        "source_csv" => @csv_path.to_s,
        "generated_at" => Time.current.iso8601,
        "family_count" => families.size,
        "sku_count" => rows.size,
        "families" => families
      ))

      {
        families_path: Paths.families_json,
        family_count: families.size,
        sku_count: rows.size
      }
    end
  end
end
