module PagesHelper

  # Méthode privée pour déterminer le chemin de l'image (URL complète ou fichier local)
  def image_path_helper(image)
    return nil unless image.present?
    # Si l'image commence par http:// ou https://, c'est une URL complète
    if image.start_with?('http://', 'https://')
      image
    else
      # Sinon, c'est un fichier local dans /images/
      "/images/#{image}"
    end
  end

  def page_header(title, subtitle = nil, image1: nil, image2: nil, with_images: true, height: nil)
    if with_images
      # Hauteur par défaut ou personnalisée
      height_style = height.present? ? "height: #{height};" : "height: 500px;"
      # Structure avec deux images côte à côte et overlay
      content_tag :div, class: "position-relative w-100 mb-5 page-header-container", style: height_style, data: { aos: "fade" } do
        # Container des deux images côte à côte
        images_container = content_tag :div, class: "d-flex h-100" do
          img1 = if image1.present?
            image_path = image_path_helper(image1)
            content_tag :div, class: "page-header-image-wrapper", style: "width: 50%; height: 100%; overflow: hidden;" do
              image_tag(image_path, class: "img-fluid page-header-image", style: "width: 100%; height: 100%; object-fit: cover; transition: transform 0.6s ease;", data: { page_header_image: "1" })
            end
          else
            content_tag(:div, class: "d-flex align-items-center justify-content-center", style: "width: 50%; height: 100%; background: linear-gradient(135deg, #2c2c2c 0%, #1a1a1a 100%); border-right: 1px solid #444;") do
              content_tag(:i, nil, class: "bi bi-image text-white-50", style: "font-size: 4rem; opacity: 0.3;")
            end
          end
          
          img2 = if image2.present?
            image_path = image_path_helper(image2)
            content_tag :div, class: "page-header-image-wrapper", style: "width: 50%; height: 100%; overflow: hidden;" do
              image_tag(image_path, class: "img-fluid page-header-image", style: "width: 100%; height: 100%; object-fit: cover; transition: transform 0.6s ease;", data: { page_header_image: "2" })
            end
          else
            content_tag(:div, class: "d-flex align-items-center justify-content-center", style: "width: 50%; height: 100%; background: linear-gradient(135deg, #2c2c2c 0%, #1a1a1a 100%);") do
              content_tag(:i, nil, class: "bi bi-image text-white-50", style: "font-size: 4rem; opacity: 0.3;")
            end
          end
          
          img1 + img2
        end
        
        # Overlay avec titre et sous-titre
        overlay = content_tag :div, class: "position-absolute top-0 start-0 w-100 h-100 d-flex flex-column justify-content-center align-items-start", 
          style: "background: linear-gradient(to right, rgba(0,0,0,0.5), rgba(0,0,0,0.3)); padding: 3rem; pointer-events: none;" do
          title_tag = content_tag(:h1, title, class: "text-white fw-bold fs-1 mb-3 text-uppercase page-header-title", data: { aos: "fade-up", aos_delay: "100" })
          subtitle_tag = if subtitle.present?
            content_tag(:h2, subtitle, class: "text-white-50 fs-5 fw-light page-header-subtitle", data: { aos: "fade-up", aos_delay: "200" })
          else
            "".html_safe
          end
          title_tag + subtitle_tag
        end
        
        images_container + overlay
      end
    else
      # Comportement par défaut sans images
      content_tag :div, class: "container-fluid text-start w-100 py-5", data: { aos: "fade" } do
        concat content_tag(:h1, title, class: "text-white fw-bold fs-1 mb-3 text-uppercase page-header-title", data: { aos: "fade-up", aos_delay: "100" })
        if subtitle.present?
          concat content_tag(:h2, subtitle, class: "text-white-50 fs-5 fw-light page-subtitle page-header-subtitle", data: { aos: "fade-up", aos_delay: "200" })
        end
      end
    end
  end

  def nav_card_scroll(index:, icon:, title:, description:, url:, image: nil)
    content_tag :div, class: "scroll-card", data: { card_index: index } do
      content_tag :div, class: "card shadow nav-card rounded-4 bg-darker-gradient text-light overflow-hidden" do
        # Image de fond (non cliquable)
        card_image = image.present? ? content_tag(:div, class: "nav-card-image-wrapper") do
          image_tag("/images/#{image}", alt: title, class: "nav-card-image")
        end : ""
        
        # Contenu cliquable (icône, titre, description, flèche)
        clickable_content = link_to url, class: "text-decoration-none nav-card-link" do
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
        
        (card_image + clickable_content).html_safe
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
      content_tag :div, class: "collection-card position-relative overflow-hidden", style: "height: 400px;" do
        # Image de fond
        image_section = if image.present?
          image_tag("/images/#{image}",
            class: "img-fluid w-100 h-100",
            loading: "lazy",
            style: "object-fit: cover; height: 100%; transition: transform 0.3s ease;"
          )
        else
          content_tag :div, class: "d-flex align-items-center justify-content-center bg-secondary w-100 h-100" do
            content_tag(:i, nil, class: "bi bi-image fs-1 text-light")
          end
        end

        # Overlay avec bouton en bas uniquement
        overlay = content_tag :div, class: "position-absolute top-0 start-0 w-100 h-100 d-flex align-items-end justify-content-center", style: "background: linear-gradient(to bottom, rgba(0,0,0,0.2), rgba(0,0,0,0.6)); padding: 1.5rem;" do
          # Bouton en bas avec le nom de la collection
          content_tag :span, class: "btn btn-outline-light btn-lg", style: "border-radius: 4px; border-width: 2px; pointer-events: auto;" do
            title
          end
        end

        image_section + overlay
      end
    end
  end

  def image_text_section(image1:, image2: nil, title:, paragraphs: [], reverse: false)
    # Déterminer l'ordre des colonnes
    image_order = reverse ? "" : "order-1 order-md-2"
    text_order = reverse ? "" : "order-2 order-md-1"
    
    content_tag :div, class: "container-fluid px-0" do
      content_tag :div, class: "row g-0 align-items-stretch" do
        # Colonne Texte
        text_col = content_tag :div, class: "col-12 col-md-6 #{text_order} d-flex" do
          content_tag :div, class: "p-4 p-md-5 d-flex flex-column justify-content-center bg-white w-100" do
            title_wrapper = content_tag :div, class: "section-title-wrapper mb-4", data: { aos: "title-underline" } do
              title_tag = content_tag(:h3, title, class: "public-brand-color section-title", style: "font-family: 'Playfair Display', serif; font-size: 2rem; position: relative; display: inline-block;")
              underline = content_tag(:span, "", class: "section-title-underline")
              title_tag + underline
            end
            paragraphs_tags = paragraphs.map do |paragraph|
              content_tag(:p, paragraph, class: "text-dark", style: "font-size: 1.1rem; line-height: 1.8;")
            end.join.html_safe
            (title_wrapper + paragraphs_tags).html_safe
          end
        end
        
        # Colonne Image
        image_col = content_tag :div, class: "col-12 col-md-6 #{image_order} d-flex" do
          image_container = content_tag :div, class: "image-hover-container w-100 h-100", style: "overflow: hidden;" do
            base_image = image_tag("/images/#{image1}", class: "image-hover-base", style: "object-fit: cover; transition: opacity 0.5s ease;")
            if image2.present?
              overlay_image = image_tag("/images/#{image2}", class: "image-hover-overlay", style: "object-fit: cover; transition: opacity 0.5s ease;")
              base_image + overlay_image
            else
              base_image
            end
          end
          image_container
        end
        
        # Inverser l'ordre si reverse est true
        reverse ? (image_col + text_col) : (text_col + image_col)
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
      # MAIS seulement si aucun autre lien n'est déjà actif
      if !is_active && params[:controller] == "public/pages" && params[:action] == "produits" && params[:from_cabine].blank? && path == nos_collections_url
        is_active = true
      end
      classes << "active" if is_active
  
      content_tag :li, class: classes do
        link_to path, class: "text-decoration-none nav-link-public #{is_active ? 'nav-link-active' : ''}" do
          content_tag(:span, name, class: "text-light fw-bold")
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
      card_footer_class = "card-footer mt-3 pt-3 p-0"
      
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
          class: "btn btn-sm w-100 btn-light hover-lift public-btn-border-radius" do
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
          class: "btn btn-sm w-100 btn-light hover-lift public-btn-border-radius" do
        (content_tag(:i, nil, class: "bi bi-bag-plus me-2") + "Ajouter au panier").html_safe
      end
    end
  end

end
