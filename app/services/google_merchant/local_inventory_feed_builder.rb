# frozen_string_literal: true

module GoogleMerchant
  # RSS 2.0 local inventory feed for Google Merchant Center (store pickup).
  class LocalInventoryFeedBuilder
    GOOGLE_NS = "http://base.google.com/ns/1.0"
    DEFAULT_STORE_CODE = "14941325208231197348"
    PICKUP_METHOD = "buy"
    PICKUP_SLA = "next_day"

    class << self
      def feed_scope
        scope = Produit.actif
          .eshop_diffusion
          .joins(:image1_attachment)
          .where("produits.prixvente > 0")
          .where(today_availability: true)
          .select(:id, :prixvente)
        limit = ENV["MERCHANT_LOCAL_FEED_LIMIT"].presence&.to_i
        limit&.positive? ? scope.limit(limit) : scope
      end

      def store_code
        ENV.fetch("MERCHANT_LOCAL_STORE_CODE", DEFAULT_STORE_CODE)
      end
    end

    def initialize(
      products:,
      channel_title:,
      channel_link:,
      channel_description:,
      store_code: self.class.store_code
    )
      @products = products
      @channel_title = channel_title
      @channel_link = channel_link
      @channel_description = channel_description
      @store_code = store_code
    end

    def to_xml
      xm = Builder::XmlMarkup.new(indent: 2)
      xm.instruct!(:xml, version: "1.0", encoding: "UTF-8")
      xm.rss(version: "2.0", "xmlns:g" => GOOGLE_NS) do
        xm.channel do
          xm.title(@channel_title)
          xm.link(@channel_link)
          xm.description(@channel_description)
          @products.find_each do |produit|
            xm.item do
              xm.tag!("g:id", FeedFormatting.item_id(produit))
              xm.tag!("g:store_code", @store_code)
              xm.tag!("g:availability", "in_stock")
              xm.tag!("g:quantity", quantity_for(produit))
              xm.tag!("g:price", FeedFormatting.format_price_eur(produit.prixvente))
              xm.tag!("g:pickup_method", PICKUP_METHOD)
              xm.tag!("g:pickup_sla", PICKUP_SLA)
            end
          end
        end
      end
      xm.target!
    end

    private

    def quantity_for(_produit)
      # Scope is today_availability: true — at least one unit is available today.
      # Avoid statut_disponibilite (~8 SQL queries/product); feed must stay under Heroku's 30s timeout.
      1
    end
  end
end
