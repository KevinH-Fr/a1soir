# frozen_string_literal: true

module SeoPages
  class ProductKeywords
    RANSACK_FIELD = :nom_or_description_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_cont

    SLUG_SEARCH_TERMS = [
      [/boheme/, "boheme"],
      [/sirene/, "sirene"],
      [/princesse/, "princesse"],
      [/fourreau/, "fourreau"],
      [/invitee/, "invitee"],
      [/gala/, "gala"]
    ].freeze

    CATEGORY_FOCUSED_SLUG_PATTERN = /smoking-ou-costume|costume-mariage|location-smoking-costume/

    def self.call(page)
      new(page).call
    end

    def self.search_string(page)
      call(page).join(" ")
    end

    def self.apply(scope, page)
      terms = call(page).flat_map { |term| variants_for(term) }.uniq
      return scope if terms.blank?

      ids = terms.flat_map { |term| pluck_ids_for_search_term(scope, term) }.uniq

      return scope.none if ids.empty?

      scope.where(id: ids)
    end

    # DISTINCT (ex. by_categories) + ORDER BY (ex. public_listing_order) + jointures ransack → PG invalide.
    def self.pluck_ids_for_search_term(scope, term)
      scope.reorder(nil).ransack(RANSACK_FIELD => term).result.reorder(nil).pluck(:id)
    end

    def self.variants_for(term)
      case term.to_s.downcase
      when "bohème", "boheme" then %w[bohème boheme]
      when "sirène", "sirene" then %w[sirène sirene]
      when "invitée", "invitee" then %w[invitée invitee]
      when "soirée", "soiree" then %w[soirée soiree]
      else
        [term]
      end
    end

    def initialize(page)
      @page = page
    end

    def call
      explicit = @page.dig(:product_filters, :search_terms) || @page.dig(:product_filters, :search_term)
      return Array(explicit).map(&:to_s).reject(&:blank?) if explicit.present?

      term = term_from_slug(@page[:slug].to_s)
      term.present? ? [term] : []
    end

    private

    def term_from_slug(slug)
      return nil if slug.match?(CATEGORY_FOCUSED_SLUG_PATTERN)

      SLUG_SEARCH_TERMS.each do |pattern, term|
        return term if slug.match?(pattern)
      end

      nil
    end
  end
end
