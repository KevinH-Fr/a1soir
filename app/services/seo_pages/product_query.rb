# frozen_string_literal: true

module SeoPages
  class ProductQuery
    HANDLE_DEDUP_FETCH_MULTIPLIER = 4
    MAX_SQL_LIMIT = 200

    def self.scope_for(page, limit: nil, require_image: false, dedupe_by_handle: true)
      new(page, limit: limit, require_image: require_image, dedupe_by_handle: dedupe_by_handle).call
    end

    def self.deduplicate_by_handle(products)
      seen = {}
      products.each_with_object([]) do |product, unique|
        key = product.handle.presence || "id_#{product.id}"
        next if seen[key]

        seen[key] = true
        unique << product
      end
    end

    def initialize(page, limit: nil, require_image: false, dedupe_by_handle: true)
      @page = page
      @limit = limit
      @require_image = require_image
      @dedupe_by_handle = dedupe_by_handle
    end

    def call
      categories = CategoryScope.call(@page)
      return Produit.none if categories.empty?

      base = Produit.actif
                    .eshop_diffusion
                    .where(today_availability: true)
                    .for_public_listing_cards
                    .includes(:categorie_produits)
                    .by_categories(categories.map(&:id))
                    .public_listing_order

      scoped = apply_keywords(base)
      scoped = base if scoped.none? && ProductKeywords.call(@page).present?

      sql_limit = sql_limit_for(@limit)
      scoped = scoped.limit(sql_limit) if sql_limit
      products = scoped.to_a

      if @require_image
        products = products.select { |product| product_visual_media?(product) }
        if products.empty? && ProductKeywords.call(@page).present?
          fallback = base
          fallback = fallback.limit(sql_limit) if sql_limit
          products = fallback.to_a.select { |product| product_visual_media?(product) }
        end
      end

      products = self.class.deduplicate_by_handle(products) if @dedupe_by_handle
      products = products.first(@limit) if @limit
      products
    end

    private

    def apply_keywords(scope)
      ProductKeywords.apply(scope, @page)
    end

    def product_visual_media?(product)
      product.image1.attached? || product.video1.attached?
    end

    def sql_limit_for(limit)
      return nil unless limit

      [limit * HANDLE_DEDUP_FETCH_MULTIPLIER, MAX_SQL_LIMIT].min
    end
  end
end
