# frozen_string_literal: true

module SeoPages
  class Registry
    CONFIG_PATH = Rails.root.join("config/seo_pages.yml").freeze

    class << self
      def all
        @all ||= load_pages.values.map(&:deep_symbolize_keys)
      end

      def find(slug, scope:)
        key = page_key(slug, scope)
        page = load_pages[key]
        return nil unless page

        page.deep_symbolize_keys.merge(slug: slug.to_s, scope: scope.to_s)
      end

      def find!(slug, scope:)
        find(slug, scope:) || raise(ActiveRecord::RecordNotFound, "SEO page not found: #{scope}/#{slug}")
      end

      def local_slugs
        @local_slugs ||= all.select { |p| p[:scope] == "local" }.map { |p| p[:slug] }.freeze
      end

      def local_slug?(slug)
        local_slugs.include?(slug.to_s)
      end

      def grouped_for_hub
        all.group_by { |p| p[:hub_group].presence || "other" }
      end

      def related_pages(page)
        Array(page[:related_pages]).filter_map do |ref|
          ref = ref.deep_symbolize_keys
          if ref[:scope] == "redirect"
            { slug: ref[:slug], scope: "redirect" }
          else
            find(ref[:slug], scope: ref[:scope])
          end
        end
      end

      def sitemap_entries
        all.map do |page|
          {
            path: public_path_for(page),
            changefreq: page.dig(:sitemap, :changefreq) || "monthly",
            priority: page.dig(:sitemap, :priority) || 0.7
          }
        end
      end

      def public_path_for(page)
        if page[:scope] == "guides"
          "/guides/#{page[:slug]}"
        else
          "/#{page[:slug]}"
        end
      end

      def page_key(slug, scope)
        "#{scope}/#{slug}"
      end

      def i18n_key(page)
        page[:slug].to_s.tr("-", "_")
      end

      def reload!
        @all = nil
        @local_slugs = nil
        @pages = nil
      end

      private

      def load_pages
        @pages ||= begin
          raw = YAML.load_file(CONFIG_PATH).fetch("pages", {})
          raw.each_with_object({}) do |(slug, config), memo|
            scope = config.fetch("scope", "local")
            memo[page_key(slug, scope)] = config.merge("slug" => slug.to_s, "scope" => scope)
          end
        end
      end
    end
  end
end
