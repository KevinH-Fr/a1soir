# frozen_string_literal: true

module SeoPages
  class CategoryImages
    PRODUCT_POOL_LIMIT = 120
    VIDEO_SCORE_BONUS = 3

    # Sections coupe / style : correspondance dans le nom produit uniquement.
    TITLE_ONLY_SECTION_KEYS = %w[princesse].freeze

    SECTION_KEYWORDS = {
      "femmes" => %w[robe longues courtes],
      "hommes" => %w[costume smoking],
      "smoking" => %w[smoking smokings],
      "costume" => %w[costume],
      "collections" => %w[courtes longues tulle dentelle costume smoking],
      "enfants" => %w[enfants enfant garçon page],
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
      "morphologie" => %w[morphologie silhouette princesse sirène sirene fourreau bustier robe mariée mariee],
      "coupe" => %w[princesse sirène sirene fourreau bustier bohème boheme coupe robe],
      "erreurs" => %w[robe costume],
      "saison_lieu" => %w[jardin plage domaine extérieur],
      "couleurs" => %w[ivoire champagne nude pastel],
      "festival" => %w[festival cannes],
      "comparatif" => %w[location achat],
      "expertise" => %w[cannes boutique],
      "accessoires_homme" => %w[papillon pochette ceinture cravate],
      "bustier" => %w[bustier corsage dos],
      "acces" => %w[boutique cannes],
      "univers" => %w[robe cocktail longue soirée],
      "location_ou_achat" => %w[robe cocktail longue soirée],
      "essayage_retouches" => %w[robe cocktail longue soirée]
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

    # Section → catégorie produit explicite (nom en base, minuscules).
    SECTION_TARGET_CATEGORY_NAMES = {
      "enfants" => ["enfants"]
    }.freeze

    # Sections éditoriales : pas de filtre strict sur le nom produit (évite les sections vides).
    EDITORIAL_SECTION_KEYS = %w[delais budget conseils histoire deroulement].freeze

    # Landing costumes : le héros et chaque section suivent le sujet du texte,
    # pas le mot « costume » du slug (qui ramenait aussi les smokings).
    COSTUME_LANDING_HERO_KEYWORDS = %w[cour xviiie marquise marquis renaissance epoque habit historique].freeze
    COSTUME_LANDING_SECTION_KEYWORDS = {
      "collection" => %w[cour xviiie marquise renaissance epoque habit historique],
      "themes" => %w[marquis marquise xviiie],
      "essayage" => %w[cour habit epoque robe],
      "scene" => %w[carnaval masque deguisement bal pirate feerie]
    }.freeze
    COSTUME_LANDING_DEGUISEMENT_SECTIONS = %w[scene].freeze

    def self.call(page, section_keys: [], exclude_product_ids: [])
      new(page, section_keys: section_keys, exclude_product_ids: exclude_product_ids).call
    end

    def self.hero_for(page)
      new(page, section_keys: []).hero_media
    end

    def self.resolve(page, section_keys: [])
      builder = new(page, section_keys: section_keys)
      hero = builder.hero_media
      builder.exclude!(hero[:product_id]) if hero
      { hero: hero, sections: builder.call }
    end

    def initialize(page, section_keys: [], exclude_product_ids: [])
      @page = page
      @section_keys = Array(section_keys).map(&:to_s)
      @exclude_product_ids = Array(exclude_product_ids)
    end

    def exclude!(product_id)
      @exclude_product_ids << product_id if product_id
    end

    def hero_media
      products = load_product_pool.select { |product| product.image1.attached? }
      return nil if products.empty?

      product = choose_varied_product(products, keywords_for_slug(@page[:slug].to_s), [], "hero")
      return nil unless product

      {
        media_type: :image,
        image: product.image1,
        position: section_position_for(product),
        product_id: product.id
      }
    end

    def call
      products = load_product_pool
      return {} if products.empty?

      build_sections(products)
    end

    private

    def load_categories
      CategoryScope.call(@page)
    end

    def load_product_pool
      @product_pool ||= ProductQuery.scope_for(
        @page,
        limit: PRODUCT_POOL_LIMIT,
        require_image: true,
        dedupe_by_handle: false
      )
    end

    def build_sections(products)
      slug_keywords = keywords_for_slug(@page[:slug].to_s)
      used_blob_ids = []
      used_product_ids = Array(@exclude_product_ids).dup
      used_category_ids = []

      result = @section_keys.each_with_object({}) do |section_key, memo|
        assign_section_media!(
          memo,
          section_key,
          products,
          slug_keywords,
          used_blob_ids,
          used_product_ids,
          used_category_ids
        )
      end

      fill_missing_sections!(
        result,
        products,
        slug_keywords,
        used_blob_ids,
        used_product_ids,
        used_category_ids
      )
      result
    end

    def assign_section_media!(memo, section_key, products, slug_keywords, used_blob_ids, used_product_ids, used_category_ids)
      keywords = section_search_terms(section_key, slug_keywords)
      product = pick_product(
        products,
        keywords,
        used_blob_ids,
        used_product_ids,
        used_category_ids,
        section_key: section_key
      )
      return unless product

      register_used_media!(product, used_blob_ids)
      used_product_ids << product.id
      used_category_ids.concat(product.categorie_produits.map(&:id))
      memo[section_key] = section_media_payload(product)
    end

    def fill_missing_sections!(result, products, slug_keywords, used_blob_ids, used_product_ids, used_category_ids)
      (@section_keys - result.keys).each do |section_key|
        product = fill_missing_pick(products, used_blob_ids, used_product_ids, used_category_ids, section_key)
        next unless product

        register_used_media!(product, used_blob_ids)
        used_product_ids << product.id
        used_category_ids.concat(product.categorie_produits.map(&:id))
        result[section_key] = section_media_payload(product)
      end
    end

    def fill_missing_pick(products, used_blob_ids, used_product_ids, used_category_ids, section_key)
      if (category_names = SECTION_TARGET_CATEGORY_NAMES[section_key.to_s]).present?
        product = pick_product_from_category_names(
          category_names,
          [],
          used_blob_ids,
          used_product_ids,
          used_category_ids,
          section_key: section_key
        )
        return product if product
      end

      pool = products.select do |product|
        product_has_media?(product) &&
          !used_product_ids.include?(product.id) &&
          media_available?(product, used_blob_ids)
      end
      pool = narrow_to_preferred_costume_tier(pool)
      return nil if pool.empty?

      sorted = pool.sort_by { |product| fallback_sort_key(product, used_category_ids) }
      sorted[stable_section_index(section_key, sorted.size)]
    end

    def section_search_terms(section_key, slug_keywords)
      terms = section_keyword_list(section_key)
      return slug_keywords if terms.blank?

      terms
    end

    def section_keyword_list(section_key)
      if costume_landing?
        landing_terms = COSTUME_LANDING_SECTION_KEYWORDS[section_key.to_s]
        return landing_terms if landing_terms.present?
      end

      SECTION_KEYWORDS[section_key.to_s]
    end

    def pick_product(products, keywords, used_blob_ids, used_product_ids, used_category_ids, section_key: nil)
      products = prefer_available_costume_products(products, used_product_ids) unless skip_epoque_preference?(section_key)
      product = pick_product_for_section(
        products, keywords, used_blob_ids, used_product_ids, used_category_ids, section_key: section_key
      )
      product || fallback_pick_product(products, used_blob_ids, used_product_ids, used_category_ids, section_key)
    end

    def pick_product_for_section(products, keywords, used_blob_ids, used_product_ids, used_category_ids, section_key: nil)
      if (category_names = SECTION_TARGET_CATEGORY_NAMES[section_key.to_s]).present?
        product = pick_product_from_category_names(
          category_names,
          keywords,
          used_blob_ids,
          used_product_ids,
          used_category_ids,
          section_key: section_key
        )
        return product if product
      end

      pool = available_products(products, used_blob_ids, used_product_ids)
      return nil if pool.empty?

      section_terms = section_keyword_list(section_key)
      if section_terms.present? && !editorial_section?(section_key)
        pool = pool.select { |product| product_matches_section?(product, section_terms, section_key: section_key) }
        pool = load_section_products(section_terms, used_blob_ids, used_product_ids) if pool.empty?
        pool = load_section_products(WEDDING_DRESS_TERMS, used_blob_ids, used_product_ids) if pool.empty? && wedding_dress_fallback?(section_key, section_terms)
        return nil if pool.empty?
      end

      choose_varied_product(pool, keywords, used_category_ids, section_key)
    end

    def pick_product_from_category_names(category_names, keywords, used_blob_ids, used_product_ids, used_category_ids, section_key:)
      categories = category_names.filter_map { |name| CategorieProduit.find_by(nom: name.to_s.downcase) }
      return nil if categories.empty?

      scoped = base_product_scope(categories).limit(PRODUCT_POOL_LIMIT).to_a
      pool = select_available_products(scoped, used_blob_ids, used_product_ids)
      return nil if pool.empty?

      choose_varied_product(pool, keywords, used_category_ids, section_key)
    end

    def fallback_pick_product(products, used_blob_ids, used_product_ids, used_category_ids, section_key)
      pool = products.select do |product|
        product_has_media?(product) &&
          !used_product_ids.include?(product.id) &&
          media_available?(product, used_blob_ids)
      end
      return nil if pool.empty?

      pool = narrow_to_preferred_costume_tier(pool)
      sorted = pool.sort_by { |product| fallback_sort_key(product, used_category_ids) }
      sorted[stable_section_index(section_key, sorted.size)]
    end

    def fallback_sort_key(product, used_category_ids)
      category_ids = product.categorie_produits.map(&:id)
      overlap = (category_ids & used_category_ids).size
      [
        product.video1.attached? ? 0 : 1,
        overlap,
        -category_ids.size,
        product.id
      ]
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
      return false unless product_has_media?(product)

      if product.video1.attached? && used_blob_ids.include?(product.video1.blob.id)
        return false
      end

      if product.image1.attached? && used_blob_ids.include?(product.image1.blob.id)
        return false
      end

      true
    end

    def choose_varied_product(pool, keywords, used_category_ids, section_key)
      pool = narrow_to_preferred_costume_tier(pool) unless skip_epoque_preference?(section_key)
      return nil if pool.empty?

      scored = pool.map { |product| [product, score_product(product, keywords, used_category_ids, section_key: section_key)] }
      max_score = scored.map(&:last).max
      if max_score.to_i.zero?
        sorted = pool.sort_by { |product| fallback_sort_key(product, used_category_ids) }
        return sorted[stable_section_index(section_key, sorted.size)]
      end

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

    def costume_landing?
      @page[:slug].to_s == "costumes-depoque"
    end

    # La section « scène » parle de carnaval, de masque et de fête : un déguisement y est le bon visuel.
    def skip_epoque_preference?(section_key)
      costume_landing? && COSTUME_LANDING_DEGUISEMENT_SECTIONS.include?(section_key.to_s)
    end

    def prefer_epoque_media?
      ActiveModel::Type::Boolean.new.cast(@page.dig(:product_filters, :prefer_epoque_media))
    end

    # Tant qu'il reste un costume d'époque, les déguisements ne sont pas candidats.
    def prefer_available_costume_products(products, used_product_ids)
      return products unless prefer_epoque_media?

      remaining = products.reject { |product| used_product_ids.include?(product.id) }
      narrow_to_preferred_costume_tier(remaining)
    end

    def narrow_to_preferred_costume_tier(pool)
      return pool unless prefer_epoque_media?
      return pool if pool.blank?

      best = pool.map { |product| RubriqueCostume.media_priority(product) }.min
      pool.select { |product| RubriqueCostume.media_priority(product) == best }
    end

    def product_matches_section?(product, section_terms, section_key: nil)
      searchable = section_searchable_text(product, section_key)
      section_terms.any? { |term| searchable.include?(search_term(term)) }
    end

    def section_searchable_text(product, section_key)
      if title_only_section?(section_key)
        product.nom.to_s.downcase
      else
        product_searchable_text(product)
      end
    end

    def title_only_section?(section_key)
      TITLE_ONLY_SECTION_KEYS.include?(section_key.to_s)
    end

    def product_searchable_text(product)
      parts = [
        product.nom,
        product.description,
        *product.categorie_produits.map(&:nom)
      ]
      parts.concat(product.rubrique_costumes.map(&:nom)) if costume_catalogue_page?
      text = parts.compact.join(" ")
      costume_catalogue_page? ? RubriqueCostume.fold(text) : text.downcase
    end

    def search_term(term)
      value = term.to_s
      costume_catalogue_page? ? RubriqueCostume.fold(value) : value.downcase
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
      ids = terms.flat_map { |term| ProductKeywords.pluck_ids_for_search_term(base_scope, term) }.uniq

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
             .public_listing_order
    end

    def select_available_products(products, used_blob_ids, used_product_ids)
      products.select do |product|
        product_has_media?(product) &&
          !used_product_ids.include?(product.id) &&
          media_available?(product, used_blob_ids)
      end
    end

    def editorial_section?(section_key)
      EDITORIAL_SECTION_KEYS.include?(section_key.to_s)
    end

    def wedding_dress_fallback?(section_key, section_terms)
      return true if section_key.to_s == "morphologie"

      wedding_dress_section?(section_terms)
    end

    def wedding_dress_section?(section_terms)
      (section_terms & WEDDING_DRESS_TERMS).empty? &&
        section_terms.any? { |term| %w[sirène sirene princesse fourreau boheme bohème coupe].include?(term.to_s.downcase) }
    end

    def score_product(product, keywords, used_category_ids = [], section_key: nil)
      searchable = if title_only_section?(section_key)
        product.nom.to_s.downcase
      else
        product_searchable_text(product)
      end
      page_terms = ProductKeywords.call(@page).flat_map { |term| ProductKeywords.variants_for(term) }
      terms = (keywords + page_terms).map { |term| search_term(term) }.uniq

      term_score = terms.count { |keyword| searchable.include?(keyword) }
      category_bonus = product.categorie_produits.none? { |category| used_category_ids.include?(category.id) } ? 2 : 0
      video_bonus = product.video1.attached? ? VIDEO_SCORE_BONUS : 0

      term_score + category_bonus + video_bonus
    end

    def keywords_for_slug(slug)
      return COSTUME_LANDING_HERO_KEYWORDS if slug == "costumes-depoque"

      patterns = slug.match?(ACCESSORY_PAGE_PATTERN) ? ACCESSORY_SLUG_KEYWORDS : SLUG_KEYWORDS

      patterns.filter_map do |pattern, keywords|
        keywords if slug.match?(pattern)
      end.flatten.uniq
    end

    def section_position_for(product)
      return "center top" if costume_catalogue_page?

      normalized = product.categorie_produits.first&.nom.to_s.downcase
      return "center top" if normalized.match?(/mariée|mariee/)
      return "top" if normalized.match?(/costume|smoking/)

      "center"
    end

    def costume_catalogue_page?
      @page.dig(:product_filters, :catalogue).to_s == Produit::CATALOGUE_COSTUME_EPOQUE_DEGUISEMENTS
    end
  end
end
