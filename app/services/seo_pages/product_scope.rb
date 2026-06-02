# frozen_string_literal: true

module SeoPages
  class ProductScope
    DEFAULT_LIMIT = 6

    def self.call(page, limit: DEFAULT_LIMIT, exclude_product_ids: [])
      fetch_limit = (limit + exclude_product_ids.size) * ProductQuery::HANDLE_DEDUP_FETCH_MULTIPLIER
      products = ProductQuery.scope_for(page, limit: fetch_limit, require_image: true)
      products = products.reject { |product| exclude_product_ids.include?(product.id) }
      products.first(limit)
    end
  end
end
