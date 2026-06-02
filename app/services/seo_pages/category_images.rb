# frozen_string_literal: true

module SeoPages
  class CategoryImages
    PRODUCT_POOL_LIMIT = 80
    VIDEO_SCORE_BONUS = 3

    SECTION_KEYWORDS = {
      "femmes" => %w[robe longues courtes],
      "hommes" => %w[costume smoking],
      "smoking" => %w[smoking smokings],
      "costume" => %w[costume],
      "collections" => %w[courtes longues tulle dentelle costume smoking],
      "enfants" => %w[enfant garçon page],
      "dresscode" => %w[cocktail gala cérémonie],
      "location" => %w[location smoking costume],
      "style" => %w[princesse sirène fourreau bohème],
      "matieres" => %w[dentelle tulle satin crêpe],
      "mariage" => %w[mariée mariee robe],
      "sirene" => %w[sirène sirene],
      "princesse" => %w[princesse],
      "fourreau" => %w[fourreau],
      "deroulement" => %w[essayage cabine rendez-vous],
      "conseils" => %w[conseil accompagnement],
      "boutique" => %w[boutique cannes],
      "formules" => %w[smoking costume location],
      "essayage" => %w[essayage cabine],
      "delais" => %w[planning calendrier],
      "budget" => %w[collection prix],
      "achat" => %w[robe costume],
      "occasions" => %w[gala mariage festival],
      "services" => %w[retouche atelier couture],
      "chaussures" => %w[chaussure escarpin sandale],
      "accessoires" => %w[accessoire voile bijou pochette],
      "coordonner" => %w[accessoire chaussure pochette],
      "histoire" => %w[collection robe],
      "retouches" => %w[atelier couture retouche],
      "morphologie" => %w[morphologie silhouette],
      "erreurs" => %w[robe costume],
      "coupe" => %w[princesse sirène fourreau bustier],
      "saison_lieu" => %w[jardin plage domaine extérieur],
      "couleurs" => %w[ivoire champagne nude pastel],
      "festival" => %w[festival cannes],
      "comparatif" => %w[location achat],
      "expertise" => %w[cannes boutique],
      "accessoires_homme" => %w[papillon pochette ceinture cravate],
      "bustier" => %w[bustier corsage dos],
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
      used_product_ids = []
      used_category_ids = []

      @section_keys.each_with_object({}) do |section_key, memo|
        next if SECTION_KEYWORDS.key?(section_key) && SECTION_KEYWORDS[section_key].empty?

        keywords = section_search_terms(section_key, slug_keywords)
        product = pick_product(
          products,
          keywords,
          used_blob_ids,
          used_product_ids,
          used_category_ids,
          section_key: section_key
        )
        next unless product

        register_used_media!(product, used_blob_ids)
        used_product_ids << product.id
        used_category_ids.concat(product.categorie_produits.map(&:id))

        memo[section_key] = section_media_payload(product)
      end
    end

    def section_search_terms(section_key, slug_keywords)
      terms = SECTION_KEYWORDS[section_key.to_s]
      return slug_keywords if terms.blank?

      terms
    end

    def pick_product(products, keywords, used_blob_ids, used_product_ids, used_category_ids, section_key: nil)
      pool = available_products(products, used_blob_ids, used_product_ids)
      return nil if pool.empty?

      section_terms = SECTION_KEYWORDS[section_key.to_s]
      if section_terms.present?
        pool = pool.select { |product| product_matches_section?(product, section_terms) }
        pool = load_section_products(section_terms, used_blob_ids, used_product_ids) if pool.empty?
        pool = load_section_products(WEDDING_DRESS_TERMS, used_blob_ids, used_product_ids) if pool.empty? && wedding_dress_section?(section_terms)
        return nil if pool.empty?
      end

      choose_varied_product(pool, keywords, used_category_ids, section_key)
    end

    def available_products(products, used_blob_ids, used_product_ids)
      products.select do |product|
        product_has_media?(product) &&
          !used_product_ids.include?(product.id) &&
          media_available?(product, used_blob_ids)
      end
    end

    def section_media_payload(product)
      if product.video1.attached?
        {
          media_type: :video,
          video: product.video1,
          image: product.image1.attached? ? product.image1 : nil,
          position: section_position_for(product),
          product_id: product.id
        }
      else
        {
          media_type: :image,
          video: nil,
          image: product.image1,
          position: section_position_for(product),
          product_id: product.id
        }
      end
    end

    def register_used_media!(product, used_blob_ids)
      used_blob_ids << product.image1.blob.id if product.image1.attached?
      used_blob_ids << product.video1.blob.id if product.video1.attached?
    end

    def product_has_media?(product)
      product.image1.attached? || product.video1.attached?
    end

    def media_available?(product, used_blob_ids)
      primary_blob = product.video1.attached? ? product.video1.blob : product.image1.blob
      !used_blob_ids.include?(primary_blob.id)
    end

    def choose_varied_product(pool, keywords, used_category_ids, section_key)
      scored = pool.map { |product| [product, score_product(product, keywords, used_category_ids)] }
      max_score = scored.map(&:last).max
      return nil if max_score.to_i.zero?

      threshold = [max_score - 1, 1].max
      candidates = scored.select { |_, score| score >= threshold }.map(&:first)
      candidates = candidates.sort_by { |product| diversity_sort_key(product, used_category_ids) }
      candidates[stable_section_index(section_key, candidates.size)]
    end

    def diversity_sort_key(product, used_category_ids)
      category_ids = product.categorie_produits.map(&:id)
      overlap = (category_ids & used_category_ids).size
      [overlap, -category_ids.size, product.id]
    end

    def stable_section_index(section_key, size)
      return 0 if size <= 1

      Zlib.crc32("#{@page[:slug]}-#{section_key}") % size
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

    def load_section_products(section_terms, used_blob_ids, used_product_ids)
      categories = CategoryScope.call(@page)
      return [] if categories.empty?

      base_scope = base_product_scope(categories)

      by_category = categories_for_terms(section_terms, categories)
      if by_category.any?
        products = base_scope.by_categories(by_category.map(&:id)).limit(PRODUCT_POOL_LIMIT).to_a
        selected = select_available_products(products, used_blob_ids, used_product_ids)
        return selected if selected.any?
      end

      select_available_products(find_by_text_terms(section_terms, base_scope), used_blob_ids, used_product_ids)
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

    def select_available_products(products, used_blob_ids, used_product_ids)
      products.select do |product|
        product_has_media?(product) &&
          !used_product_ids.include?(product.id) &&
          media_available?(product, used_blob_ids)
      end
    end

    def wedding_dress_section?(section_terms)
      (section_terms & WEDDING_DRESS_TERMS).empty? &&
        section_terms.any? { |term| %w[sirène sirene princesse fourreau boheme bohème].include?(term.to_s.downcase) }
    end

    def score_product(product, keywords, used_category_ids = [])
      searchable = product_searchable_text(product)
      page_terms = ProductKeywords.call(@page).flat_map { |term| ProductKeywords.variants_for(term) }
      terms = (keywords + page_terms).map(&:to_s).map(&:downcase).uniq

      term_score = terms.count { |keyword| searchable.include?(keyword) }
      category_bonus = product.categorie_produits.none? { |category| used_category_ids.include?(category.id) } ? 2 : 0
      video_bonus = product.video1.attached? ? VIDEO_SCORE_BONUS : 0

      term_score + category_bonus + video_bonus
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
