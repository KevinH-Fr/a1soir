# frozen_string_literal: true

module SeoPages
  class CategoryImages
    PRODUCT_POOL_LIMIT = 30

    SECTION_KEYWORDS = {
      "femmes" => %w[robe],
      "hommes" => %w[costume smoking],
      "smoking" => %w[smoking smokings],
      "costume" => %w[costume],
      "collections" => %w[costume smoking],
      "enfants" => %w[costume enfant],
      "dresscode" => %w[robe],
      "location" => %w[robe],
      "style" => %w[mariée mariee robe],
      "matieres" => %w[mariée mariee robe],
      "mariage" => %w[mariée mariee robe],
      "sirene" => %w[sirène sirene],
      "princesse" => %w[princesse],
      "fourreau" => %w[fourreau],
      "deroulement" => %w[mariée mariee robe],
      "conseils" => %w[mariée mariee robe],
      "boutique" => %w[mariée mariee robe],
      "formules" => %w[costume smoking],
      "essayage" => %w[mariée mariee robe],
      "delais" => %w[mariée mariee robe],
      "budget" => %w[mariée mariee robe],
      "achat" => %w[robe],
      "occasions" => %w[robe costume smoking],
      "services" => %w[mariée mariee robe costume],
      "chaussures" => %w[chaussure],
      "accessoires" => %w[accessoire],
      "coordonner" => %w[accessoire chaussure],
      "acces" => []
    }.freeze

    SLUG_KEYWORDS = [
      [/mariee|mariée|essayage|boheme|morphologie|choisir/, %w[mariée mariee robe]],
      [/costume|smoking/, %w[costume smoking]],
      [/soiree|soirée|gala|invitee|location|achat/, %w[robe costume smoking]]
    ].freeze

    ACCESSORY_SLUG_KEYWORDS = [
      [/chaussures|accessoires/, %w[chaussure accessoire]]
    ].freeze

    ACCESSORY_PAGE_PATTERN = /chaussures|accessoires/

    WEDDING_DRESS_TERMS = %w[mariée mariee robe].freeze

    def self.call(page, section_keys: [])
      new(page, section_keys: section_keys).call
    end

    def initialize(page, section_keys: [])
      @page = page
      @section_keys = Array(section_keys).map(&:to_s)
    end

    def call
      categories = load_categories
      products = load_products(categories)
      return {} if products.empty?

      build_sections(products)
    end

    private

    def load_categories
      CategoryScope.call(@page)
    end

    def load_products(categories)
      return [] if categories.empty?

      ProductQuery.scope_for(@page, limit: PRODUCT_POOL_LIMIT, require_image: true)
    end

    def build_sections(products)
      slug_keywords = keywords_for_slug(@page[:slug].to_s)
      used_blob_ids = []

      @section_keys.each_with_object({}) do |section_key, memo|
        next if SECTION_KEYWORDS.key?(section_key) && SECTION_KEYWORDS[section_key].empty?

        keywords = section_search_terms(section_key, slug_keywords)
        product = pick_product(products, keywords, used_blob_ids, section_key: section_key)
        next unless product

        used_blob_ids << product.image1.blob.id

        memo[section_key] = {
          image: product.image1,
          position: section_position_for(product)
        }
      end
    end

    def section_search_terms(section_key, slug_keywords)
      terms = SECTION_KEYWORDS[section_key.to_s]
      return slug_keywords if terms.blank?

      terms
    end

    def pick_product(products, keywords, used_blob_ids, section_key: nil)
      pool = products.reject { |product| used_blob_ids.include?(product.image1.blob.id) }
      return nil if pool.empty?

      section_terms = SECTION_KEYWORDS[section_key.to_s]
      if section_terms.present?
        pool = pool.select { |product| product_matches_section?(product, section_terms) }
        pool = load_section_products(section_terms, used_blob_ids) if pool.empty?
        pool = load_section_products(WEDDING_DRESS_TERMS, used_blob_ids) if pool.empty? && wedding_dress_section?(section_terms)
        return nil if pool.empty?
      end

      pool.max_by { |product| score_product(product, keywords) }
    end

    def product_matches_section?(product, section_terms)
      searchable = product_searchable_text(product)
      section_terms.any? { |term| searchable.include?(term.to_s.downcase) }
    end

    def product_searchable_text(product)
      [
        product.nom,
        product.description,
        *product.categorie_produits.map(&:nom)
      ].compact.join(" ").downcase
    end

    def load_section_products(section_terms, used_blob_ids)
      categories = CategoryScope.call(@page)
      return [] if categories.empty?

      base_scope = base_product_scope(categories)

      by_category = categories_for_terms(section_terms, categories)
      if by_category.any?
        products = base_scope.by_categories(by_category.map(&:id)).limit(PRODUCT_POOL_LIMIT).to_a
        selected = select_available_products(products, used_blob_ids)
        return selected if selected.any?
      end

      select_available_products(find_by_text_terms(section_terms, base_scope), used_blob_ids)
    end

    def categories_for_terms(section_terms, categories)
      categories.select do |category|
        name = category.nom.to_s.downcase
        section_terms.any? { |term| name.include?(term.to_s.downcase) }
      end
    end

    def find_by_text_terms(section_terms, base_scope)
      terms = section_terms.flat_map { |term| ProductKeywords.variants_for(term) }.uniq
      ids = terms.flat_map do |term|
        base_scope.ransack(ProductKeywords::RANSACK_FIELD => term).result.pluck(:id)
      end.uniq

      return [] if ids.empty?

      base_scope.where(id: ids).limit(PRODUCT_POOL_LIMIT).to_a
    end

    def base_product_scope(categories)
      Produit.actif
             .eshop_diffusion
             .where(today_availability: true)
             .for_public_listing_cards
             .includes(:categorie_produits)
             .by_categories(categories.map(&:id))
    end

    def select_available_products(products, used_blob_ids)
      products.select do |product|
        product.image1.attached? && !used_blob_ids.include?(product.image1.blob.id)
      end
    end

    def wedding_dress_section?(section_terms)
      (section_terms & WEDDING_DRESS_TERMS).empty? &&
        section_terms.any? { |term| %w[sirène sirene princesse fourreau boheme bohème].include?(term.to_s.downcase) }
    end

    def score_product(product, keywords)
      searchable = product_searchable_text(product)
      page_terms = ProductKeywords.call(@page).flat_map { |term| ProductKeywords.variants_for(term) }
      terms = (keywords + page_terms).map(&:to_s).map(&:downcase).uniq

      terms.count { |keyword| searchable.include?(keyword) }
    end

    def keywords_for_slug(slug)
      patterns = slug.match?(ACCESSORY_PAGE_PATTERN) ? ACCESSORY_SLUG_KEYWORDS : SLUG_KEYWORDS

      patterns.filter_map do |pattern, keywords|
        keywords if slug.match?(pattern)
      end.flatten.uniq
    end

    def section_position_for(product)
      normalized = product.categorie_produits.first&.nom.to_s.downcase
      return "center top" if normalized.match?(/mariée|mariee/)
      return "top" if normalized.match?(/costume|smoking/)

      "center"
    end
  end
end
