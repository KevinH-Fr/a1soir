# frozen_string_literal: true

require "builder"
require "zlib"

module Sitemap
  # Builds sitemap XML from the public catalogue (same rules as legacy config/sitemap.rb).
  class Builder
    include Rails.application.routes.url_helpers

    SITEMAP_XMLNS = "http://www.sitemaps.org/schemas/sitemap/0.9"

    STATIC_PAGES = [
      ["/home", "weekly", 1.0],
      ["/la_boutique", "weekly", 0.9],
      ["/nos_collections", "weekly", 0.9],
      ["/le_concept", "monthly", 0.8],
      ["/nos_autres_activites", "monthly", 0.8],
      ["/festival-de-cannes", "daily", 0.9],
      ["/cabine_essayage", "weekly", 0.8],
      ["/contact", "monthly", 0.7],
      ["/rdv", "weekly", 0.8],
      ["/produits", "daily", 0.6],
      ["/categories", "weekly", 0.7],
      ["/faq", "monthly", 0.7],
      ["/legal", "yearly", 0.4],
      ["/guides", "weekly", 0.7]
    ].freeze

    class << self
      def default_host
        if Rails.env.production?
          ENV.fetch("SITEMAP_HOST", "https://a1soir.com")
        else
          ENV.fetch("SITEMAP_HOST", "http://localhost:3000")
        end
      end

      def write!(path = Rails.root.join("public", "sitemap.xml.gz"))
        File.binwrite(path, new.to_gzip)
        path
      end
    end

    def initialize(host: nil)
      @host = host.presence || self.class.default_host
      uri = URI.parse(@host.to_s)
      @default_url_options = {
        host: uri.host.presence || "localhost",
        protocol: uri.scheme.presence || "https"
      }
    end

    attr_reader :default_url_options

    def entries
      @entries ||= build_entries
    end

    def to_xml
      xml = ::Builder::XmlMarkup.new(indent: 2)
      xml.instruct!(:xml, version: "1.0", encoding: "UTF-8")
      xml.urlset(xmlns: SITEMAP_XMLNS) do
        entries.each do |entry|
          xml.url do
            xml.loc(entry[:loc])
            xml.lastmod(entry[:lastmod]) if entry[:lastmod].present?
            xml.changefreq(entry[:changefreq])
            xml.priority(format("%.1f", entry[:priority]))
          end
        end
      end
      xml.target!
    end

    def to_gzip
      buffer = StringIO.new
      Zlib::GzipWriter.wrap(buffer) { |gz| gz.write(to_xml) }
      buffer.string
    end

    private

    def build_entries
      items = []

      STATIC_PAGES.each do |path, changefreq, priority|
        [:fr, :en].each do |locale|
          items << entry(
            loc: absolute_path("/#{locale}#{path}"),
            changefreq: changefreq,
            priority: priority
          )
        end
      end

      items.concat(seo_page_entries)

      CategorieProduit.not_service.find_each do |categorie|
        [:fr, :en].each do |locale|
          items << entry(
            loc: produits_url(
              slug: categorie.nom.parameterize,
              id: categorie.id,
              locale: locale
            ),
            changefreq: "weekly",
            priority: 0.7,
            lastmod: categorie.updated_at
          )
        end
      end

      Produit.actif
             .eshop_diffusion
             .where(today_availability: true)
             .find_each do |produit|
        [:fr, :en].each do |locale|
          items << entry(
            loc: produit_url(
              slug: produit.handle,
              id: produit.id,
              locale: locale
            ),
            changefreq: "weekly",
            priority: 0.5,
            lastmod: produit.updated_at
          )
        end
      end

      items
    end

    def entry(loc:, changefreq:, priority:, lastmod: nil)
      {
        loc: loc,
        changefreq: changefreq,
        priority: priority,
        lastmod: lastmod&.iso8601
      }
    end

    def absolute_path(path)
      base = @host.to_s.chomp("/")
      "#{base}#{path}"
    end

    def seo_page_entries
      SeoPages::Registry.sitemap_entries.flat_map do |seo_entry|
        [:fr, :en].map do |locale|
          entry(
            loc: absolute_path("/#{locale}#{seo_entry[:path]}"),
            changefreq: seo_entry[:changefreq],
            priority: seo_entry[:priority]
          )
        end
      end
    end
  end
end
