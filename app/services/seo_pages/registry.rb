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

      RELATED_PAGES_TARGET = 6

      def related_pages(page)
        explicit = resolve_related_refs(page)
        return explicit if explicit.size >= RELATED_PAGES_TARGET

        extras = supplemental_related_pages(page, exclude: explicit)
        explicit + extras.first(RELATED_PAGES_TARGET - explicit.size)
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

      def resolve_related_refs(page)
        Array(page[:related_pages]).filter_map do |ref|
          ref = ref.deep_symbolize_keys
          if ref[:scope] == "redirect"
            { slug: ref[:slug], scope: "redirect" }
          else
            find(ref[:slug], scope: ref[:scope])
          end
        end
      end

      def supplemental_related_pages(page, exclude:)
        excluded_keys = exclude.map { |entry| page_key(entry[:slug], entry[:scope]) }.to_set
        excluded_keys << page_key(page[:slug], page[:scope])

        candidate_pools = [
          pool_same_hub_group(page),
          pool_complementary_hub_group(page),
          pool_all_pages
        ]

        candidate_pools.flatten
          .uniq { |entry| page_key(entry[:slug], entry[:scope]) }
          .reject { |entry| excluded_keys.include?(page_key(entry[:slug], entry[:scope])) }
      end

      def pool_same_hub_group(page)
        all
          .select { |entry| entry[:hub_group] == page[:hub_group] }
          .sort_by { |entry| related_sort_key(entry) }
      end

      def pool_complementary_hub_group(page)
        groups = case page[:hub_group]
                 when "local" then %w[guides services]
                 when "guides" then %w[local services events]
                 when "events" then %w[guides services local]
                 when "services" then %w[guides local events]
                 else []
                 end

        all
          .select { |entry| groups.include?(entry[:hub_group]) }
          .sort_by { |entry| related_sort_key(entry) }
      end

      def pool_all_pages
        all
          .reject { |entry| entry[:scope] == "redirect" }
          .sort_by { |entry| related_sort_key(entry) }
      end

      def related_sort_key(entry)
        hub_rank = SEO_HUB_GROUP_ORDER.index(entry[:hub_group]) || 99
        [hub_rank, entry[:footer_order] || 999, entry[:slug]]
      end

      SEO_HUB_GROUP_ORDER = %w[local guides events services].freeze

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
