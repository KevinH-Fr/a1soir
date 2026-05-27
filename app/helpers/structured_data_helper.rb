module StructuredDataHelper
  # Schéma global de la boutique (entreprise)
  def clothing_store_schema
    {
      "@context" => "https://schema.org",
      "@type" => "ClothingStore",
      "name" => "Autour D'Un Soir",
      "url" => root_url,
      "image" => "#{root_url}images/autourdunsoir_drapeau.png"
    }
  end

  # Schéma global du site
  def website_schema
    {
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => "Autour D'Un Soir",
      "url" => root_url
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
      { name: structured_breadcrumb_name(:home), url: root_url },
      { name: structured_breadcrumb_name(:products), url: produits_index_url }
    ]

    categorie = produit.categorie_produits.merge(CategorieProduit.not_service).order(:nom).first
    if categorie
      crumbs << {
        name: categorie.nom,
        url: produits_url(slug: categorie.nom.parameterize, id: categorie.id)
      }
    end

    crumbs << { name: produit.nom, url: request.original_url }
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
        url: request.original_url
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
    {
      "@type" => "ClothingStore",
      "name" => "Autour D'Un Soir",
      "url" => root_url,
      "image" => "#{root_url}images/autourdunsoir_drapeau.png"
    }
  end

  def website_node
    {
      "@type" => "WebSite",
      "name" => "Autour D'Un Soir",
      "url" => root_url
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

