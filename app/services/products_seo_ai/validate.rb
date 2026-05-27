# frozen_string_literal: true

require "csv"
require "json"
require "set"

module ProductsSeoAi
  class Validate
    GENERIC_TITLES = /\A(costume|robe|veste|pantalon|gilet|chemise|jupe|sandales?|chaussures?|accessoire)\z/i

    def self.call(csv_path:)
      new(csv_path: csv_path).call
    end

    def initialize(csv_path: nil)
      path = csv_path || Config.import_csv
      @csv_path = Pathname.new(path)
      @csv_path = Rails.root.join(@csv_path) unless @csv_path.absolute?
    end

    def call
      abort "CSV introuvable : #{@csv_path}" unless @csv_path.exist?

      rows = CSV.read(@csv_path, headers: true)
      warnings = []
      errors = []

      by_handle = rows.group_by { |r| r["handle"].to_s.strip }

      by_handle.each do |handle, group|
        new_noms = group.map { |r| r["new_nom"].to_s.strip }.uniq
        if new_noms.size > 1
          errors << "handle=#{handle} : #{new_noms.size} new_nom distincts → #{new_noms.inspect}"
        end

        group.each do |row|
          id = row["id"]
          new_nom = row["new_nom"].to_s.strip
          approved = row["approved"].to_s.strip.downcase

          if approved == "yes" && new_nom.blank?
            errors << "id=#{id} approved=yes mais new_nom vide"
          end

          if new_nom.present? && new_nom.match?(GENERIC_TITLES)
            warnings << "id=#{id} handle=#{handle} : titre trop générique « #{new_nom} »"
          end
        end
      end

      families_data = load_families_if_present
      if families_data
        ai_handles = load_ai_handles
        missing_ai = families_data.keys - ai_handles.to_a
        missing_ai.each { |h| warnings << "handle=#{h} : pas de résultat IA (batch manquant)" }

        families_data.each do |handle, family|
          next unless ai_handles.include?(handle)

          couleurs = family["couleurs"] || []
          tailles = family["tailles"] || []
          group = by_handle[handle] || []
          new_nom = group.first&.[]("new_nom").to_s.strip
          next if new_nom.blank?

          couleurs.each do |c|
            next if c.blank?

            warnings << "handle=#{handle} : couleur « #{c} » peut-être dans new_nom" if new_nom.downcase.include?(c.downcase)
          end

          tailles.each do |t|
            next if t.blank?

            warnings << "handle=#{handle} : taille « #{t} » peut-être dans new_nom" if new_nom.match?(/\b#{Regexp.escape(t)}\b/i)
          end
        end
      end

      approved_count = rows.count { |r| r["approved"].to_s.strip.downcase == "yes" }
      report_path = Paths.root.join("validation_report.txt")

      report = []
      report << "CSV : #{@csv_path}"
      report << "Lignes : #{rows.size}"
      report << "Approved (yes) : #{approved_count}"
      report << "Handles : #{by_handle.size}"
      report << ""
      report << "ERREURS (#{errors.size})"
      report << (errors.any? ? errors.join("\n") : "  (aucune)")
      report << ""
      report << "WARNINGS (#{warnings.size})"
      report << (warnings.any? ? warnings.join("\n") : "  (aucun)")

      Paths.ensure_dirs!
      File.write(report_path, report.join("\n"))

      puts report.join("\n")
      puts
      puts "Rapport : #{report_path}"

      {
        errors: errors,
        warnings: warnings,
        report_path: report_path
      }
    end

    private

    def load_families_if_present
      return nil unless Paths.families_json.exist?

      data = JSON.parse(File.read(Paths.families_json))
      (data["families"] || []).index_by { |f| f["handle"] }
    end

    def load_ai_handles
      return Set.new unless Paths.batches_dir.exist?

      handles = Set.new
      Dir.glob(Paths.batches_dir.join("*.json")).each do |path|
        payload = JSON.parse(File.read(path))
        (payload["items"] || []).each { |item| handles << item["handle"].to_s.strip }
      end
      handles
    end
  end
end
