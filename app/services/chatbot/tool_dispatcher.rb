require "json"
require "uri"

module Chatbot
  class ToolDispatcher
    class UnknownToolError < StandardError; end

    STORE_INFO = {
      name: "Autour D'Un Soir",
      phone_display: "04 93 45 17 17",
      phone_link: "+33493451717",
      address: "27-29 Boulevard Carnot, 06400 Cannes",
      parking: ["Parking Mozart", "Parking St Nicolas", "Parking Vauban"]
    }.freeze

    FALLBACK_OPENING_HOURS = [
      "Lundi: 10:00 - 17:00",
      "Mardi-Vendredi: 10:00 - 12:00 / 15:00 - 19:00",
      "Samedi: 10:00 - 17:00",
      "Dimanche: Ferme"
    ].freeze

    FAQ_FACTS = {
      appointment: "Le rendez-vous est recommande (et necessaire pour essayages/retouches).",
      rent_duration: "La location standard est de 4 jours (2 jours avant + 2 jours apres l'evenement).",
      deposit: "Une caution proportionnelle a la valeur de la tenue est demandee au retrait.",
      down_payment: "Un acompte de 30% est demande a la reservation.",
      withdrawal: "Droit de retractation de 14 jours sous conditions (produit non porte, etat d'origine, etiquettes, emballage).",
      children: "Selection de tenues garcon (6 mois a 18 ans), location ou vente.",
      delivery: "Retrait boutique gratuit; livraison selon conditions pour les articles achetes."
    }.freeze

    def self.definitions
      [
        {
          type: "function",
          name: "search_products",
          description: "Search products by name and return availability.",
          strict: true,
          parameters: {
            type: "object",
            properties: {
              query: {
                type: "string",
                description: "Product name or keyword to search"
              }
            },
            required: ["query"],
            additionalProperties: false
          }
        },
        {
          type: "function",
          name: "get_store_info",
          description: "Return shop identity, address, phone and opening hours.",
          strict: true,
          parameters: {
            type: "object",
            properties: {},
            required: [],
            additionalProperties: false
          }
        },
        {
          type: "function",
          name: "get_service_links",
          description: "Return official URLs for appointment, fitting room, contact, FAQ, legal, e-shop, concept (rental/sale), other activities, and boutique.",
          strict: true,
          parameters: {
            type: "object",
            properties: {
              topic: {
                type: "string",
                description: "Topic key: all, rdv, cabine, cabine_reservation, contact, faq, legal, eshop, boutique, concept, autres_activites",
                enum: %w[all rdv cabine cabine_reservation contact faq legal eshop boutique concept autres_activites]
              }
            },
            required: ["topic"],
            additionalProperties: false
          }
        },
        {
          type: "function",
          name: "get_policy_faq_facts",
          description: "Return key policy and FAQ facts (deposit, duration, appointment, withdrawal, etc).",
          strict: true,
          parameters: {
            type: "object",
            properties: {},
            required: [],
            additionalProperties: false
          }
        }
      ]
    end

    def self.call(name:, arguments:, base_url:, locale:)
      normalized = arguments.is_a?(String) ? JSON.parse(arguments) : arguments
      normalized = {} unless normalized.is_a?(Hash)

      case name
      when "search_products"
        search_products(normalized, base_url: base_url, locale: locale)
      when "get_store_info"
        get_store_info
      when "get_service_links"
        get_service_links(normalized, base_url: base_url, locale: locale)
      when "get_policy_faq_facts"
        get_policy_faq_facts
      else
        raise UnknownToolError, "Unsupported tool: #{name}"
      end
    rescue JSON::ParserError
      { error: "Invalid tool arguments payload." }
    rescue StandardError => error
      {
        error: "Tool execution failed.",
        details: "#{error.class}: #{error.message}"
      }
    end

    def self.search_products(arguments, base_url:, locale:)
      query = arguments["query"].to_s.strip
      return { error: "Missing query argument." } if query.blank?

      terms = query.downcase.split.uniq.first(4)
      relation = Produit.left_joins(:type_produit, :categorie_produits, :couleur, :taille)
                        .includes(:couleur, :taille, :type_produit, :categorie_produits)

      terms.each do |term|
        relation = relation.where(
          "(LOWER(produits.nom) LIKE :q
            OR LOWER(COALESCE(produits.description, '')) LIKE :q
            OR LOWER(COALESCE(produits.handle, '')) LIKE :q
            OR LOWER(COALESCE(type_produits.nom, '')) LIKE :q
            OR LOWER(COALESCE(categorie_produits.nom, '')) LIKE :q
            OR LOWER(COALESCE(couleurs.nom, '')) LIKE :q
            OR LOWER(COALESCE(tailles.nom, '')) LIKE :q)",
          q: "%#{term}%"
        )
      end

      relation = relation.where(actif: true) if Produit.column_names.include?("actif")
      relation = relation.distinct.order("produits.nom ASC").limit(8)

      helpers = Rails.application.routes.url_helpers
      products = relation.map { |p| format_product(p, base_url: base_url, locale: locale, helpers: helpers) }

      if products.empty?
        fallback = Produit
                   .where(actif: true, eshop: true)
                   .where(today_availability: true)
                   .includes(:couleur, :taille, :type_produit, :categorie_produits)
                   .order(coup_de_coeur: :desc, updated_at: :desc)
                   .limit(5)
                   .map { |p| format_product(p, base_url: base_url, locale: locale, helpers: helpers) }

        return {
          query: query,
          count: 0,
          products: [],
          fallback_products: fallback,
          note: "No direct product match. Returning currently available e-shop suggestions."
        }
      end

      {
        query: query,
        count: products.size,
        products: products
      }
    end

    def self.get_store_info
      STORE_INFO.merge(opening_hours: fetch_opening_hours)
    end

    def self.fetch_opening_hours
      lines = Texte.last&.horaire&.to_plain_text&.split("\n")&.reject(&:blank?)
      lines.presence || FALLBACK_OPENING_HOURS
    rescue StandardError
      FALLBACK_OPENING_HOURS
    end

    def self.get_service_links(arguments, base_url:, locale:)
      links = service_links(base_url: base_url, locale: locale)
      topic = arguments["topic"].to_s.strip.downcase
      return links if topic.blank? || topic == "all"

      value = links[topic.to_sym]
      return { topic: topic, url: value } if value.present?

      {
        error: "Unknown topic.",
        allowed_topics: links.keys.map(&:to_s)
      }
    end

    def self.get_policy_faq_facts
      FAQ_FACTS
    end

    def self.service_links(base_url:, locale:)
      helpers = Rails.application.routes.url_helpers
      {
        rdv: absolute_url(base_url, helpers.rdv_path(locale: locale), "rdv-form"),
        contact: absolute_url(base_url, helpers.contact_path(locale: locale), "message-form"),
        cabine: absolute_url(base_url, helpers.cabine_essayage_path(locale: locale)),
        cabine_reservation: absolute_url(base_url, helpers.new_demande_cabine_essayage_path(locale: locale)),
        faq: absolute_url(base_url, helpers.faq_path(locale: locale)),
        legal: absolute_url(base_url, helpers.legal_path(locale: locale)),
        eshop: absolute_url(base_url, helpers.produits_index_path(locale: locale)),
        boutique: absolute_url(base_url, helpers.la_boutique_path(locale: locale)),
        concept: absolute_url(base_url, helpers.le_concept_path(locale: locale)),
        autres_activites: absolute_url(base_url, helpers.nos_autres_activites_path(locale: locale))
      }
    end

    def self.absolute_url(base_url, path, anchor = nil)
      normalized_base = base_url.to_s
      normalized_base = "https://a1soir.com" if normalized_base.blank?
      uri = URI.join("#{normalized_base}/", path.sub(%r{\A/}, ""))
      uri.fragment = anchor if anchor.present?
      uri.to_s
    end

    def self.format_product(produit, base_url:, locale:, helpers:)
      slug = produit.handle.presence || produit.nom.to_s.parameterize
      path = helpers.produit_path(locale: locale, slug: slug, id: produit.id)
      {
        id: produit.id,
        nom: produit.nom,
        description: produit.description.to_s.truncate(140),
        today_availability: produit.today_availability,
        eshop: produit.eshop,
        prixvente: produit.prixvente,
        prixlocation: produit.prixlocation,
        caution: produit.caution,
        ancien_prixvente: produit.ancien_prixvente,
        couleur: produit.couleur&.nom,
        taille: produit.taille&.nom,
        type_produit: produit.type_produit&.nom,
        categories: produit.categorie_produits.map(&:nom),
        url: absolute_url(base_url, path)
      }
    end
    private_class_method :format_product
  end
end
