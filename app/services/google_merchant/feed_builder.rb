# frozen_string_literal: true

module GoogleMerchant
  # RSS 2.0 + http://base.google.com/ns/1.0 for Google Merchant Center (v1 attributes only).
  class FeedBuilder
    GOOGLE_NS = "http://base.google.com/ns/1.0"
    CLOUDINARY_IMAGE_BASE = "https://res.cloudinary.com/dukne3lhz/image/upload".freeze
    IMAGE_TRANSFORM = "q_auto,f_auto,w_1200"
    FEED_BRAND = "Autour D'Un Soir".freeze

    class << self
      def feed_scope
        Produit.actif
          .eshop_diffusion
          .joins(:image1_attachment)
          .where("produits.prixvente > 0")
          .includes(:image1_attachment, :taille, :couleur, :categorie_produits)
      end

      def format_shipping_weight_kg(grams)
        kg = grams.to_f / 1000.0
        return "0 kg" if kg <= 0

        text = if (kg - kg.round).abs < 1e-9
                 kg.round.to_s
               else
                 s = format("%.3f", kg).sub(/\.?0+\z/, "")
                 s.presence || "0"
               end
        "#{text} kg"
      end
    end

    def initialize(products:, channel_title:, channel_link:, channel_description:, host:, protocol: "https")
      @products = products
      @channel_title = channel_title
      @channel_link = channel_link
      @channel_description = channel_description
      @host = host
      @protocol = protocol.to_s.presence || "https"
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
            next unless produit.image1.attached?

            xm.item do
              xm.tag!("g:id", FeedFormatting.item_id(produit))
              xm.tag!("g:title", truncate_plain(produit.nom, 150))
              xm.tag!("g:description", truncate_plain(strip_description(produit.description), 5000))
              xm.tag!("g:link", produit_url_for(produit))
              xm.tag!("g:image_link", image_url_for(produit))
              xm.tag!("g:availability", availability_for(produit))
              xm.tag!("g:condition", "new")
              xm.tag!("g:price", FeedFormatting.format_price_eur(produit.prixvente))
              xm.tag!("g:brand", FEED_BRAND)
              xm.tag!("g:shipping_weight", self.class.format_shipping_weight_kg(produit.poids.to_i))
              xm.tag!("g:item_group_id", produit.handle.presence || "group-#{produit.id}")
              xm.tag!("g:size", produit.taille.nom) if produit.taille&.nom.present?
              xm.tag!("g:color", produit.couleur.nom) if produit.couleur&.nom.present?
              xm.tag!("g:gender", ApparelAttributes.gender_for(produit))
              xm.tag!("g:age_group", ApparelAttributes.age_group_for(produit))
            end
          end
        end
      end
      xm.target!
    end

    private

    def produit_url_for(produit)
      Rails.application.routes.url_helpers.produit_url(
        slug: produit.nom.to_s.parameterize,
        id: produit.id,
        locale: I18n.default_locale,
        host: @host,
        protocol: @protocol
      )
    end

    def image_url_for(produit)
      key = produit.image1.blob.key
      "#{CLOUDINARY_IMAGE_BASE}/#{IMAGE_TRANSFORM}/#{key}"
    end

    def availability_for(produit)
      produit.today_availability ? "in_stock" : "out_of_stock"
    end

    def strip_description(html)
      ActionController::Base.helpers.strip_tags(html.to_s).squish
    end

    def truncate_plain(text, max)
      s = text.to_s
      return s if s.length <= max

      "#{s[0, max - 1]}…"
    end
  end
end
