# frozen_string_literal: true

module SeoPages
  class ProductQuery
    def self.scope_for(page, limit: nil, require_image: false)
      new(page, limit: limit, require_image: require_image).call
    end

    def initialize(page, limit: nil, require_image: false)
      @page = page
      @limit = limit
      @require_image = require_image
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

      scoped = apply_keywords(base)
      scoped = base if scoped.none? && ProductKeywords.call(@page).present?

      scoped = scoped.limit(@limit) if @limit
      products = scoped.to_a

      if @require_image
        products = products.select { |product| product_visual_media?(product) }
        if products.empty? && ProductKeywords.call(@page).present?
          fallback = base
          fallback = fallback.limit(@limit) if @limit
          products = fallback.to_a.select { |product| product_visual_media?(product) }
        end
      end

      products
    end

    private

    def apply_keywords(scope)
      ProductKeywords.apply(scope, @page)
    end

    def product_visual_media?(product)
      product.image1.attached? || product.video1.attached?
    end
  end
end
