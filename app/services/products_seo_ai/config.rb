# frozen_string_literal: true

module ProductsSeoAi
  module Config
    module_function

    def export_csv
      ENV.fetch("SEO_AI_EXPORT_CSV") do
        Rails.env.development? ? "tmp/produits_seo_export.csv" : "produits_seo_export_prod.csv"
      end
    end

    def import_csv
      ENV.fetch("SEO_AI_IMPORT_OUTPUT") do
        Rails.env.development? ? "tmp/produits_seo_import.csv" : "produits_seo_import_prod.csv"
      end
    end

    def default_batch_size
      Rails.env.development? ? 5 : 30
    end
  end
end
