# frozen_string_literal: true

module Constraints
  class SeoPageSlug
    def self.matches?(request)
      SeoPages::Registry.local_slug?(request.params[:slug])
    end
  end
end
