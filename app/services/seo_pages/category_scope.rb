# frozen_string_literal: true

module SeoPages
  class CategoryScope
    ACCESSORY_PAGE_PATTERN = /chaussures|accessoires/

    SLUG_EXPANSIONS = {
      /mariee|mariée|essayage|boheme|morphologie|choisir/ => [
        "robes de mariée courtes",
        "robes de mariée longues"
      ],
      /costume|smoking/ => %w[costume smokings],
      /soiree|soirée|gala|invitee|location|achat/ => [
        "robes courtes",
        "robes longues"
      ]
    }.freeze

    def self.call(page)
      new(page).call
    end

    def initialize(page)
      @page = page
    end

    def call
      names = Array(@page.dig(:product_filters, :category_names)).map { |name| name.to_s.downcase }
      slug = @page[:slug].to_s

      unless slug.match?(ACCESSORY_PAGE_PATTERN)
        SLUG_EXPANSIONS.each do |pattern, expanded|
          names.concat(expanded) if slug.match?(pattern)
        end
      end

      names.uniq.filter_map { |name| CategorieProduit.find_by(nom: name) }
    end
  end
end
