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

