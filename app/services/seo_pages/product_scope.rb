# frozen_string_literal: true

module SeoPages
  class ProductScope
    DEFAULT_LIMIT = 6

    def self.call(page, limit: DEFAULT_LIMIT)
      ProductQuery.scope_for(page, limit: limit)
    end
  end
end
