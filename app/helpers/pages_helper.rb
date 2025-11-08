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
            
            card_title = content_tag(:h3, title, class: "h2 fw-bold mb-3 nav-card-title position-relative")
            
            card_description = content_tag(:p, description, class: "text-light mb-3 nav-card-description position-relative", style: "font-size: 1.15rem; line-height: 1.6;")
            
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
      icon_tag = content_tag(:i, nil, class: "bi bi-#{icon} public-brand-color me-2")
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
    link_to url, class: "text-decoration-none" do
        content_tag :div, class: "collection-card h-100" do
          # Image section
          image_section = if image.present?
            content_tag :div, class: "collection-card-image" do
              image_tag(image, class: "w-100 h-100", style: "object-fit: cover;")
            end
          else
            content_tag :div, class: "collection-card-image collection-card-placeholder" do
              content_tag :i, nil, class: "bi bi-image"
            end
          end

          # Card body
          card_body = content_tag :div, class: "collection-card-body" do
            concat content_tag(:h5, title, class: "public-brand-color fw-bold mb-3")
            concat content_tag(:p, items.join(" • ").html_safe, class: "text-light small mb-0")
          end

          # Card footer
          card_footer = content_tag :div, class: "collection-card-footer" do
            content_tag :span, class: "text-light" do
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

  def nav_link_public(path, name)
      classes = ["nav-item text-center m-2 mx-3"]
      
      is_active = current_page?(path) || (path == home_path && current_page?(root_path))
      # Activer le lien cabine quand on revient des produits avec le paramètre from_cabine
      is_active ||= (
        path == cabine_essayage_path &&
        params[:controller] == "public/pages" &&
        params[:action] == "produits" &&
        params[:from_cabine].present?
      )
      # Sur la page produits sans paramètre from_cabine, on met en avant Collections
      if params[:controller] == "public/pages" && params[:action] == "produits" && params[:from_cabine].blank? && path == nos_collections_url
        is_active = true
      end
      classes << "active" if is_active
  
      content_tag :li, class: classes do
        link_to path, class: "text-decoration-none nav-link-public #{is_active ? 'nav-link-active' : ''}" do
          content_tag(:span, name, class: "text-light fw-bold")
        end
      end
  end

  def cabine_nav_link_item(badge_count: nil)
    classes = ["nav-item text-center m-2 mx-3"]
    is_active = current_page?(cabine_essayage_path)
    # Garde le lien actif lorsque l'on consulte la liste des produits depuis la cabine
    if params[:controller] == "public/pages" && params[:action] == "produits" && params[:from_cabine].present?
      is_active = true
    end
    classes << "active" if is_active

    content_tag :li, class: classes, id: "cabine_badge" do
      link_to cabine_essayage_url, class: "text-decoration-none nav-link-public #{is_active ? 'nav-link-active' : ''} position-relative" do
        concat content_tag(:span, "Cabine d'essayage", class: "fw-bold")
        if badge_count.present? && badge_count > 0
        concat content_tag(:span, badge_count, 
          class: "position-absolute top-0 start-100 translate-middle badge rounded-circle text-light",
          style: "background: var(--public-brand-gradient); color: #ffffff !important; width: 1.5em; height: 1.5em; display: flex; align-items: center; justify-content: center; padding-top: 0.1em;")
        end
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
  
  # Les méthodes badge_taille et badge_prix ont été déplacées dans BadgesPublicHelper
  
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

  def info_card(icon:, title:, content:)
    content_tag :div, class: "col-sm m-2 p-0" do
      content_tag :div, class: "info-card rounded p-4 h-100" do
        card_header = content_tag(:div, class: "text-center mb-3") do
          icon_tag = content_tag(:i, nil, class: "bi bi-#{icon} fs-3 public-brand-color me-2")
          title_tag = content_tag(:span, title, class: "fw-bold fs-4 text-light")
          (icon_tag + title_tag).html_safe
        end
        
        card_content = content_tag(:div, class: "text-light") do
          content.to_s.html_safe
        end
        
        (card_header + card_content).html_safe
      end
    end
  end

  def concept_card(icon:, title:, description:, features:, icon_color: "public-brand-color")
    content_tag :div, class: "concept-card h-100" do
      # Icon section
      icon_section = content_tag(:div, class: "text-center mb-4") do
        content_tag(:div, class: "concept-card-icon") do
          content_tag(:i, nil, class: "bi bi-#{icon} fs-1 #{icon_color}")
        end
      end
      
      # Title
      title_section = content_tag(:h3, title, class: "h4 fw-bold mb-3 text-center text-light")
      
      # Description
      desc_section = content_tag(:p, description, class: "text-light mb-4 opacity-75")
      
      # Features list
      features_section = content_tag(:ul, class: "list-unstyled") do
        features.map do |feature|
          content_tag(:li, class: "mb-2 text-light") do
            concat content_tag(:i, nil, class: "bi bi-check-circle-fill public-brand-color me-2")
            concat feature
          end
        end.join.html_safe
      end
      
      (icon_section + title_section + desc_section + features_section).html_safe
    end
  end

  def activity_card(icon:, title:, description:, icon_color: "public-brand-color", &block)
    content_tag :div, class: "concept-card h-100" do
      # Icon section
      icon_section = content_tag(:div, class: "mb-4") do
        content_tag(:div, class: "concept-card-icon") do
          content_tag(:i, nil, class: "bi bi-#{icon} fs-1 #{icon_color}")
        end
      end
      
      # Title
      title_section = content_tag(:h3, title, class: "h3 fw-bold mb-3 text-light")
      
      # Description
      desc_section = content_tag(:p, description, class: "text-light mb-4 opacity-75")
      
      # Custom content from block
      custom_content = capture(&block) if block_given?
      
      (icon_section + title_section + desc_section + custom_content.to_s).html_safe
    end
  end

  # Helper for legal sections
  def legal_section(id:, icon:, title:, alert: nil, &block)
    content_tag :section, id: id, class: "my-5", "data-scroll-reveal": true do
      content_tag :div, class: "concept-card" do
        # Title with icon
        title_html = content_tag(:h2, class: "h3 fw-bold mb-4 text-light") do
          concat content_tag(:i, nil, class: "bi bi-#{icon} public-brand-color me-2")
          concat title
        end
        
        # Optional alert
        alert_html = if alert
          alert_class = alert[:type] == :warning ? "alert-warning" : "alert-info"
          alert_style = alert[:type] == :warning ? 
            "background: rgba(255, 193, 7, 0.15); border: 1px solid rgba(255, 193, 7, 0.3);" :
            "background: rgba(255, 255, 255, 0.1); border: 1px solid rgba(255, 255, 255, 0.2);"
          icon_class = alert[:type] == :warning ? "text-warning" : "public-brand-color"
          
          content_tag(:div, class: "alert #{alert_class} mb-4", style: alert_style) do
            concat content_tag(:i, nil, class: "bi bi-#{alert[:icon]} #{icon_class} me-2")
            concat content_tag(:small, alert[:text], class: "text-light")
          end
        else
          "".html_safe
        end
        
        # Content from block
        content_html = capture(&block) if block_given?
        
        (title_html + alert_html + content_html.to_s).html_safe
      end
    end
  end

  # Helper for legal articles
  def legal_article(number:, title:, content:)
    content_tag :div do
      title_html = content_tag(:h4, "Article #{number} - #{title}", class: "h5 fw-bold mt-4 mb-3 text-light")
      content_html = content_tag(:p, content.html_safe, class: "text-light opacity-75")
      (title_html + content_html).html_safe
    end
  end

  # Helper for FAQ sections
  def faq_section(id:, icon:, title:, accordion_id:, &block)
    content_tag :section, id: id, class: "my-5", "data-scroll-reveal": true do
      title_html = content_tag(:div, class: "mb-4") do
        content_tag(:h2, class: "h3 fw-bold text-light") do
          concat content_tag(:i, nil, class: "bi bi-#{icon} public-brand-color me-2")
          concat title
        end
      end
      
      accordion_html = content_tag(:div, class: "accordion", id: accordion_id) do
        capture(&block) if block_given?
      end
      
      (title_html + accordion_html).html_safe
    end
  end

  # Helper for FAQ accordion items
  def faq_item(id:, parent_id:, question:, &block)
    content_tag :div, class: "accordion-item concept-card mb-3" do
      header_html = content_tag(:h3, class: "accordion-header text-light") do
        content_tag(:button, 
          class: "accordion-button collapsed text-light faq-accordion-button", 
          type: "button", 
          "data-bs-toggle": "collapse", 
          "data-bs-target": "##{id}"
        ) do
          concat content_tag(:i, nil, class: "bi bi-question-circle-fill public-brand-color me-2")
          concat question
        end
      end
      
      body_html = content_tag(:div, id: id, class: "accordion-collapse collapse", "data-bs-parent": "##{parent_id}") do
        content_tag(:div, class: "accordion-body text-light opacity-75 faq-accordion-body") do
          capture(&block) if block_given?
        end
      end
      
      (header_html + body_html).html_safe
    end
  end

  # Helper pour générer les boutons de panier (cabine ou shop) avec style commun
  def cart_button_for(produit, type: :shop)
    turbo_frame_tag "produit_#{produit.id}_button" do
      card_footer_class = "card-footer bg-transparent border-top border-secondary mt-3 pt-3 p-0"
      
      content_tag :div, class: card_footer_class do
        case type
        when :cabine
          render_cabine_button(produit)
        when :shop
          render_shop_button(produit)
        end
      end
    end
  end

  private

  def render_cabine_button(produit)
    if session[:cabine_cart].include?(produit.id)
      button_to cabine_remove_product_path(produit), method: :delete,
          class: "btn btn-sm w-100 btn-outline-danger" do
        (content_tag(:i, nil, class: "bi bi-bag-x me-2") + "Retirer de la cabine").html_safe
      end
    elsif session[:cabine_cart].size >= 10
      content_tag :button, type: "button", class: "btn btn-sm w-100 btn-secondary", disabled: true do
        (content_tag(:i, nil, class: "bi bi-exclamation-triangle me-2") + "Limite atteinte (10 produits max)").html_safe
      end
    else
      button_to cabine_add_product_path(produit),
          class: "btn btn-sm w-100 btn-smoke-hover text-light",
          style: cart_button_style do
        (content_tag(:i, nil, class: "bi bi-bag-plus me-2") + "Ajouter à la cabine").html_safe
      end
    end
  end

  def render_shop_button(produit)
    if session[:cart].include?(produit.id)
      button_to remove_from_cart_path(produit), method: :delete,
          class: "btn btn-sm w-100 btn-secondary" do
        (content_tag(:i, nil, class: "bi bi-bag-x me-2") + "Retirer du panier").html_safe
      end
    else
      button_to add_to_cart_path(produit),
          class: "btn btn-sm w-100 btn-smoke-hover text-light",
          style: cart_button_style do
        (content_tag(:i, nil, class: "bi bi-bag-plus me-2") + "Ajouter au panier").html_safe
      end
    end
  end

  def cart_button_style
    "background: var(--public-brand-gradient); border: none;"
  end

end
