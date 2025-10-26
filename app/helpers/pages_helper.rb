module PagesHelper

  def page_header(title, subtitle = nil)
    content_tag :div, class: "container-fluid text-center w-100 py-5", data: { aos: "fade" } do
      concat content_tag(:h1, title, class: "text-white fw-bold fs-1 mb-3 text-uppercase page-title", data: { aos: "fade-up", aos_delay: "100" })
      if subtitle.present?
        concat content_tag(:h2, subtitle, class: "text-white-50 fs-5 fw-light page-subtitle", data: { aos: "fade-up", aos_delay: "200" })
      end
    end
  end

  def nav_card_scroll(index:, icon:, title:, description:, url:)
    content_tag :div, class: "scroll-card", data: { card_index: index } do
      link_to url, class: "text-decoration-none" do
        content_tag :div, class: "card shadow nav-card rounded-4 bg-darker-gradient text-light overflow-hidden" do
          content_tag(:div, class: "card-body p-5 text-center position-relative", style: "z-index: 1;") do
            icon_wrapper = content_tag(:div, class: "nav-card-icon-wrapper rounded-circle d-inline-flex align-items-center justify-content-center mb-4") do
              content_tag :i, nil, class: "bi bi-#{icon} nav-card-icon d-block"
            end
            
            card_title = content_tag(:h3, title, class: "h4 fw-bold mb-3 nav-card-title position-relative")
            
            card_description = content_tag(:p, description, class: "text-light mb-3 nav-card-description position-relative", style: "font-size: 0.95rem; line-height: 1.6;")
            
            card_arrow = content_tag(:div, class: "nav-card-arrow mt-3 position-relative") do
              content_tag :i, nil, class: "bi bi-arrow-right-circle position-relative"
            end
            
            (icon_wrapper + card_title + card_description + card_arrow).html_safe
          end
        end
      end
    end
  end

  def reference_item(icon:, name:)
    content_tag :div, class: "reference-item" do
      icon_tag = content_tag(:i, nil, class: "bi bi-#{icon} brand-colored me-2")
      name_tag = content_tag(:span, name)
      (icon_tag + name_tag).html_safe
    end
  end

  def references_slider
    references = [
      { icon: 'building-fill', name: 'Le Moulin Rouge à Paris' },
      { icon: 'gem', name: 'Le Trianon Palace à Paris' },
      { icon: 'cup-hot-fill', name: 'Le Procope à Paris' },
      { icon: 'tropical-storm', name: 'Le Baoli à Cannes' },
      { icon: 'house-fill', name: 'Le Château de Vaux Le Vicomte' },
      { icon: 'dice-5-fill', name: 'Le Casino La Siesta à Antibes' },
      { icon: 'cup-straw', name: 'Le Café de Paris à Monaco' },
      { icon: 'brightness-high-fill', name: 'L\'Hôtel Belles Rives à Juan les Pins' },
      { icon: 'building', name: 'L\'Hôtel Radisson à Cannes' },
      { icon: 'star-fill', name: 'L\'Hôtel Fairmont à Monaco' },
      { icon: 'circle-fill', name: 'Le Cirque Alexis Gruss' },
      { icon: 'tv-fill', name: 'France 2' },
      { icon: 'tv', name: 'France 3' },
      { icon: 'broadcast', name: 'M6' },
      { icon: 'film', name: 'Canal +' },
      { icon: 'award-fill', name: 'Lenôtre' }
    ]

    content_tag :div, class: "references-slider-wrapper" do
      content_tag :div, class: "references-slider" do
        items = []
        # Premier ensemble
        references.each do |ref|
          items << reference_item(icon: ref[:icon], name: ref[:name])
        end
        # Duplication pour effet de défilement continu
        references.each do |ref|
          items << reference_item(icon: ref[:icon], name: ref[:name])
        end
        items.join.html_safe
      end
    end
  end

  def collection_card(title:, items:, url:, delay: 0, image: nil)
    content_tag :div, class: "col-12 col-md-6 col-lg-3", data: { aos: "fade-up", aos_delay: delay } do
      link_to url, class: "text-decoration-none" do
        content_tag :div, class: "card h-100 shadow-sm hover-card" do
          # Image section
          image_section = if image.present?
            content_tag :div, class: "card-img-top collection-card-image" do
              image_tag(image, class: "w-100 h-100", style: "object-fit: cover;")
            end
          else
            content_tag :div, class: "card-img-top bg-light d-flex align-items-center justify-content-center collection-card-image" do
              content_tag :i, nil, class: "bi bi-image text-muted"
            end
          end

          # Card body
          card_body = content_tag :div, class: "card-body text-center" do
            concat content_tag(:h5, title, class: "card-title brand-colored fw-bold")
            concat content_tag(:p, items.join(" • ").html_safe, class: "card-text text-muted small")
          end

          # Card footer
          card_footer = content_tag :div, class: "card-footer bg-white border-top-0 text-center" do
            content_tag :span, class: "text-dark" do
              concat "Découvrir "
              concat content_tag(:i, nil, class: "bi bi-arrow-right ms-1")
            end
          end

          concat image_section
          concat card_body
          concat card_footer
        end
      end
    end
  end

  def nav_link_public(path, name)
      classes = ["nav-item text-center m-2"]
      is_active = current_page?(path)
      classes << "active" if is_active
  
      content_tag :li, class: classes do
        link_to path, class: "text-decoration-none nav-link-public #{is_active ? 'nav-link-active' : ''}" do
          concat content_tag(:span, name, class: "text-light fw-bold")
        end
      end
  end

  #    laboutique_url(subdomain: "shop"),
  def card_categorie(categorie)
    link_to produits_url(subdomain: "shop", slug: categorie.nom.parameterize, id: categorie.id), class: "text-decoration-none" do
      content_tag :div, class: "card text-bg-light mb-1" do
        image_tag(categorie.default_image, class: "card-img", style: "height: 350px; object-fit: cover;") +
        content_tag(:div, class: "card-img-overlay") do
          content_tag(:h5, categorie.nom, class: "card-title badge bg-brand-colored fs-6")
        end
      end
    end
  end

  def statut_disponibilite_shop(statut)
    content_tag :span, statut, class: "border p-1 rounded text-capitalize #{statut == 'disponible' ? 'text-success' : 'text-danger'}"
  end
  
  def badge_taille(produit)
    content_tag :span, "Taille : #{produit.taille.nom.upcase}", class: "border p-1 rounded"
  end
  
  def badge_prix(type, montant)
    content_tag :span, "#{type} : #{custom_currency_no_decimals_format(montant)}", class: "border p-1 rounded"
  end
  
  def link_badge_taille_class(taille_id = nil)
    badge_class = "badge border brand-colored text-decoration-none"
    
    # If taille_id is nil (for "Toutes"), don't apply active class if a taille is selected
    if taille_id.nil?
      active_class = params[:taille].nil? ? "bg-brand-colored text-light" : ""
    else
      # If taille_id is not nil, apply active class when the size matches
      active_class = taille_id.to_i == params[:taille].to_i ? "bg-brand-colored text-light" : ""
    end
    
    "#{badge_class} #{active_class}"
  end
  
  def link_badge_couleur_class(couleur_id = nil)
    badge_class = "badge border brand-colored text-downcase text-decoration-none"
    
    # If taille_id is nil (for "Toutes"), don't apply active class if a taille is selected
    if couleur_id.nil?
      active_class = params[:couleur].nil? ? "bg-brand-colored text-light" : ""
    else
      # If taille_id is not nil, apply active class when the size matches
      active_class = couleur_id.to_i == params[:couleur].to_i ? "bg-brand-colored text-light" : ""
    end
    
    "#{badge_class} #{active_class}"
  end
  
  def link_badge_prix_class(prix = nil)
    badge_class = "badge border brand-colored text-downcase text-decoration-none"
    
    # If taille_id is nil (for "Toutes"), don't apply active class if a taille is selected
    if prix.nil?
      active_class = params[:prixmax].nil? ? "bg-brand-colored text-light" : ""
    else
      # If taille_id is not nil, apply active class when the size matches
      active_class = prix.to_i == params[:prixmax].to_i ? "bg-brand-colored text-light" : ""
    end
    
    "#{badge_class} #{active_class}"
  end
  
  def link_badge_categorie_class(categorie_id = nil)
    badge_class = "badge border brand-colored text-downcase text-decoration-none"
    
    # If taille_id is nil (for "Toutes"), don't apply active class if a taille is selected
    if categorie_id.nil?
      active_class = params[:id].nil? ? "bg-brand-colored text-light" : ""
    else
      # If taille_id is not nil, apply active class when the size matches
      active_class = categorie_id.to_i == params[:id].to_i ? "bg-brand-colored text-light" : ""
    end
    
    "#{badge_class} #{active_class}"
  end

  def link_badge_type_class(type = nil)
    badge_class = "badge border brand-colored text-downcase text-decoration-none"
    
    # If taille_id is nil (for "Toutes"), don't apply active class if a taille is selected
    if type.nil?
      active_class = params[:type].nil? ? "bg-brand-colored text-light" : ""
    else
      # If taille_id is not nil, apply active class when the size matches
      active_class = type == params[:type] ? "bg-brand-colored text-light" : ""
    end
    
    "#{badge_class} #{active_class}"
  end

  # Helper pour construire les URLs de filtres produits
  # category_names peut être un String ou un Array de Strings
  def produits_filter_url(category_names: nil, taille_name: nil, couleur_id: nil, prixmax: nil, type: nil)
    # Gérer à la fois un string et un tableau de strings
    category_names = [category_names] if category_names.is_a?(String)
    
    # Trouver les catégories par nom
    categories = []
    if category_names.present?
      categories = category_names.map { |name| CategorieProduit.find_by(nom: name.downcase) }.compact
    end
    
    # Construire les paramètres de filtres
    filter_params = {}
    if categories.present?
      # Si une seule catégorie, passer l'ID; si plusieurs, passer un tableau
      filter_params[:id] = categories.size == 1 ? categories.first.id : categories.map(&:id)
    end
    filter_params[:taille] = Taille.find_by(nom: taille_name.downcase)&.id if taille_name
    filter_params[:couleur] = couleur_id if couleur_id
    filter_params[:prixmax] = prixmax if prixmax
    filter_params[:type] = type if type
    
    # Générer l'URL
    if categories.size == 1
      produits_url(subdomain: "shop", slug: categories.first.nom.parameterize, **filter_params)
    else
      produits_index_url(subdomain: "shop", **filter_params)
    end
  end

end
