module StructuredDataHelper
  STORE_ADDRESS = {
    street: "29 Boulevard Carnot",
    locality: "Cannes",
    postal_code: "06400",
    country: "FR"
  }.freeze

  STORE_GEO = {
    latitude: 43.5523,
    longitude: 7.0178
  }.freeze

  STORE_PHONE = "+33493451717".freeze

  AREA_SERVED = [
    { "@type" => "City", "name" => "Cannes" },
    { "@type" => "City", "name" => "Nice" },
    { "@type" => "City", "name" => "Antibes" },
    { "@type" => "City", "name" => "Juan-les-Pins" },
    { "@type" => "City", "name" => "Monaco" },
    { "@type" => "City", "name" => "Mandelieu-la-Napoule" },
    { "@type" => "City", "name" => "Mougins" },
    { "@type" => "City", "name" => "Grasse" },
    { "@type" => "City", "name" => "Saint-Raphaël" },
    { "@type" => "City", "name" => "Le Cannet" },
    { "@type" => "City", "name" => "Valbonne" },
    { "@type" => "City", "name" => "Vallauris" },
    { "@type" => "AdministrativeArea", "name" => "Alpes-Maritimes" }
  ].freeze

  FAQ_SECTIONS = [
    [:general, 5],
    [:location, 7],
    [:sale, 3],
    [:alterations, 5],
    [:delivery, 2],
    [:payment, 3]
  ].freeze

  # Schéma global de la boutique (entreprise)
  def clothing_store_schema
    clothing_store_node.merge("@context" => "https://schema.org")
  end

  # Schéma global du site
  def website_schema
    {
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => "Autour D'Un Soir",
      "url" => structured_site_url
    }
  end

  # Schéma WebPage générique pour une page principale
  def webpage_schema(name:, description:, url:)
    {
      "@context" => "https://schema.org",
      "@type" => "WebPage",
      "name" => name,
      "description" => description,
      "url" => url
    }
  end

  # Schéma FAQPage pour la page FAQ
  def faq_page_schema
    {
      "@context" => "https://schema.org",
      "@type" => "FAQPage",
      "mainEntity" => faq_schema_questions
    }
  end

  # Schéma Product pour une fiche produit
  def product_schema(produit:)
    schema = {
      "@context" => "https://schema.org",
      "@type" => "Product",
      "name" => produit.nom,
      "url" => produit_url(slug: produit.handle, id: produit.id, locale: I18n.locale),
      "brand" => {
        "@type" => "Brand",
        "name" => "Autour D'Un Soir"
      }
    }

    description = ActionController::Base.helpers.strip_tags(produit.description.to_s).squish
    schema["description"] = description if description.present?

    image = product_schema_image_url(produit)
    schema["image"] = image if image.present?

    offers = product_schema_offers(produit)
    schema["offers"] = offers if offers.present?

    schema
  end

  # Libellés du fil d'Ariane JSON-LD (FR/EN via locales)
  def structured_breadcrumb_name(key)
    case key
    when :home then I18n.t("public.footer.home")
    when :products then I18n.t("public.footer.products")
    when :categories then I18n.t("public.breadcrumbs.categories")
    else
      raise ArgumentError, "Unknown breadcrumb key: #{key}"
    end
  end

  # Fil d'Ariane pour une fiche produit
  def product_breadcrumbs(produit:)
    crumbs = [
      { name: structured_breadcrumb_name(:home), url: structured_home_url },
      { name: structured_breadcrumb_name(:products), url: produits_index_url }
    ]

    categorie = produit.categorie_produits.merge(CategorieProduit.not_service).order(:nom).first
    if categorie
      crumbs << {
        name: categorie.nom,
        url: produits_url(slug: categorie.nom.parameterize, id: categorie.id)
      }
    end

    crumbs << {
      name: produit.nom,
      url: produit_url(slug: produit.handle, id: produit.id, locale: I18n.locale)
    }
    crumbs
  end

  # Schéma BreadcrumbList pour les pages avec fil d'Ariane
  # breadcrumbs: tableau de hashes { name: "Libellé", url: "https://..." }
  def breadcrumb_schema(breadcrumbs)
    {
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => breadcrumbs.each_with_index.map do |crumb, index|
        {
          "@type" => "ListItem",
          "position" => index + 1,
          "name" => crumb[:name],
          "item" => crumb[:url]
        }
      end
    }
  end

  # Schéma global sous forme de graph (entreprise + site),
  # utilisable pour un seul script JSON-LD.
  def structured_data_for(page_key: nil, breadcrumbs: nil)
    graph = []

    # Entreprise + site toujours présents
    graph << clothing_store_node
    graph << website_node

    # Page courante optionnelle
    if page_key
      graph << webpage_node(
        name: meta_title(page_key),
        description: meta_description(page_key),
        url: public_page_url
      )
    end

    # Breadcrumb optionnel
    graph << breadcrumb_node(breadcrumbs) if breadcrumbs.present?

    {
      "@context" => "https://schema.org",
      "@graph" => graph
    }
  end

  # Version simple utilisée globalement (entreprise + site uniquement)
  def structured_data_global
    {
      "@context" => "https://schema.org",
      "@graph" => [
        clothing_store_node,
        website_node
      ]
    }
  end

  private

  def faq_schema_questions
    FAQ_SECTIONS.flat_map do |section, count|
      (1..count).filter_map do |n|
        question = I18n.t("public.pages.faq.sections.#{section}.q#{n}.question", default: nil)
        next if question.blank?

        answer_html = faq_schema_answer_html(section, n)
        answer_text = ActionController::Base.helpers.strip_tags(answer_html.to_s).squish
        next if answer_text.blank?

        {
          "@type" => "Question",
          "name" => question,
          "acceptedAnswer" => {
            "@type" => "Answer",
            "text" => answer_text
          }
        }
      end
    end
  end

  def faq_schema_answer_html(section, n)
    key = "public.pages.faq.sections.#{section}.q#{n}.answer_html"
    return I18n.t(key) unless section == :general && n == 1

    I18n.t(
      key,
      address: "29 Boulevard Carnot, 06400 Cannes",
      hours: I18n.t("meta_tags.faq_schema.hours_fallback"),
      phone: "04 93 45 17 17",
      contact_link: I18n.t("public.pages.faq.sections.general.q1.contact_form")
    )
  end

  def product_schema_image_url(produit)
    return unless produit.image1.attached?

    key = produit.image1.blob.key
    "#{ApplicationHelper::CLOUDINARY_BASE_IMAGE_URL}/q_auto,f_auto,w_1200/#{key}"
  end

  def product_schema_offers(produit)
    availability = produit.today_availability ? "https://schema.org/InStock" : "https://schema.org/OutOfStock"
    offers = []

    if produit.prixvente.to_d.positive?
      offers << {
        "@type" => "Offer",
        "price" => format("%.2f", produit.prixvente.to_d),
        "priceCurrency" => "EUR",
        "availability" => availability,
        "url" => produit_url(slug: produit.handle, id: produit.id, locale: I18n.locale)
      }
    end

    if produit.prixlocation.to_d.positive?
      offers << {
        "@type" => "Offer",
        "name" => "Location",
        "price" => format("%.2f", produit.prixlocation.to_d),
        "priceCurrency" => "EUR",
        "availability" => availability,
        "url" => produit_url(slug: produit.handle, id: produit.id, locale: I18n.locale)
      }
    end

    return offers.first if offers.one?

    offers.presence
  end

  def clothing_store_node
    node = {
      "@type" => "ClothingStore",
      "name" => "Autour D'Un Soir",
      "url" => structured_home_url,
      "image" => structured_store_logo_url,
      "telephone" => STORE_PHONE,
      "address" => {
        "@type" => "PostalAddress",
        "streetAddress" => STORE_ADDRESS[:street],
        "addressLocality" => STORE_ADDRESS[:locality],
        "postalCode" => STORE_ADDRESS[:postal_code],
        "addressCountry" => STORE_ADDRESS[:country]
      },
      "geo" => {
        "@type" => "GeoCoordinates",
        "latitude" => STORE_GEO[:latitude],
        "longitude" => STORE_GEO[:longitude]
      },
      "areaServed" => AREA_SERVED
    }

    google_data = GooglePlacesService.fetch
    if google_data&.dig(:rating).present?
      node["aggregateRating"] = {
        "@type" => "AggregateRating",
        "ratingValue" => google_data[:rating],
        "reviewCount" => google_data[:user_rating_count]
      }
    end

    node.merge!(StoreOpeningHours.for_clothing_store_schema)

    node
  end

  def website_node
    {
      "@type" => "WebSite",
      "name" => "Autour D'Un Soir",
      "url" => structured_site_url
    }
  end

  def webpage_node(name:, description:, url:)
    {
      "@type" => "WebPage",
      "name" => name,
      "description" => description,
      "url" => url
    }
  end

  def breadcrumb_node(breadcrumbs)
    {
      "@type" => "BreadcrumbList",
      "itemListElement" => breadcrumbs.each_with_index.map do |crumb, index|
        {
          "@type" => "ListItem",
          "position" => index + 1,
          "name" => crumb[:name],
          "item" => crumb[:url]
        }
      end
    }
  end
end
