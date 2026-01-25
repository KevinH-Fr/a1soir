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

  def page_header(title, subtitle = nil, image1: nil, image2: nil, with_images: true, height: nil, image1_position: "center", image2_position: "center")
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
              image_tag(image_path, class: "img-fluid page-header-image", style: "width: 100%; height: 100%; object-fit: cover; object-position: #{image1_position}; transition: transform 0.6s ease;", data: { page_header_image: "1" })
            end
          else
            content_tag(:div, class: "d-flex align-items-center justify-content-center", style: "width: 50%; height: 100%; background: linear-gradient(135deg, #2c2c2c 0%, #1a1a1a 100%); border-right: 1px solid #444;") do
              content_tag(:i, nil, class: "bi bi-image text-white-50", style: "font-size: 4rem; opacity: 0.3;")
            end
          end
          
          img2 = if image2.present?
            image_path = image_path_helper(image2)
            content_tag :div, class: "page-header-image-wrapper", style: "width: 50%; height: 100%; overflow: hidden;" do
              image_tag(image_path, class: "img-fluid page-header-image", style: "width: 100%; height: 100%; object-fit: cover; object-position: #{image2_position}; transition: transform 0.6s ease;", data: { page_header_image: "2" })
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

  # Helper générique pour créer un item de slider (référence)
  def reference_item(icon:, name:)
    content_tag :div, class: "reference-item" do
      icon_tag = content_tag(:i, nil, class: "bi bi-#{icon} me-3")
      name_tag = content_tag(:span, name, class: "reference-text")
      (icon_tag + name_tag).html_safe
    end
  end

  # Helper pour créer un item de témoignage dans le slider
  def testimonial_item(text:, name:, subtitle:, icon:)
    content_tag :div, class: "testimonial-slider-item bg-dark text-light rounded-1 p-4 shadow", style: "min-width: 350px; max-width: 350px;" do
      quote = content_tag(:div, class: "mb-3") do
        content_tag(:i, nil, class: "bi bi-quote", style: "font-size: 2rem;")
      end
      
      text_content = content_tag(:p, text, class: "mb-3 opacity-75", style: "font-size: 0.95rem; line-height: 1.6;")
      
      footer = content_tag(:div, class: "d-flex align-items-center mt-auto pt-3 border-top border-secondary") do
        icon_wrapper = content_tag(:div, class: "me-3") do
          content_tag(:i, nil, class: "bi bi-#{icon}", style: "font-size: 1.5rem;")
        end
        text_wrapper = content_tag(:div) do
          name_tag = content_tag(:strong, name, class: "d-block")
          subtitle_tag = content_tag(:small, subtitle, class: "opacity-75")
          name_tag + subtitle_tag
        end
        icon_wrapper + text_wrapper
      end
      
      (quote + text_content + footer).html_safe
    end
  end

  # Helper générique pour créer un slider horizontal
  def items_slider(items:, type: :reference)
    content_tag :div, class: "references-slider-wrapper" do
      content_tag :div, class: "references-slider" do
        slider_items = []
        # Premier ensemble
        items.each do |item|
          slider_items << case type
          when :reference
            reference_item(icon: item[:icon], name: item[:name])
          when :testimonial
            testimonial_item(text: item[:text], name: item[:name], subtitle: item[:subtitle], icon: item[:icon])
          end
        end
        # Duplication pour effet de défilement continu
        items.each do |item|
          slider_items << case type
          when :reference
            reference_item(icon: item[:icon], name: item[:name])
          when :testimonial
            testimonial_item(text: item[:text], name: item[:name], subtitle: item[:subtitle], icon: item[:icon])
          end
        end
        slider_items.join.html_safe
      end
    end
  end



  def collection_card(title:, items:, url:, delay: 0, image: nil, subtitle: nil, image_position: "center")
    link_to url, class: "text-decoration-none collection-card-link" do
      content_tag :div, class: "collection-card position-relative overflow-hidden", style: "height: 600px;" do
        # Image de fond
        image_section = if image.present?
          image_tag("/images/#{image}",
            class: "img-fluid w-100 h-100 collection-card-image",
            loading: "lazy",
            style: "object-fit: cover; object-position: #{image_position};"
          )
        else
          content_tag :div, class: "d-flex align-items-center justify-content-center bg-secondary w-100 h-100" do
            content_tag(:i, nil, class: "bi bi-image fs-1 text-light")
          end
        end

        # Overlay avec titre en bas à gauche
        overlay = content_tag :div, class: "position-absolute bottom-0 start-0 p-5" do
          content_tag :h3, title, class: "text-white mb-0 collection-card-title", style: "text-shadow: 0 2px 10px rgba(0,0,0,0.8);"
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
        text_col = content_tag :div, class: "col-12 col-md-6 #{text_order} d-flex", data: { scroll_reveal: true } do
          content_tag :div, class: "p-4 p-md-5 d-flex flex-column justify-content-center bg-white w-100" do
            title_wrapper = content_tag :div, class: "section-title-wrapper mb-4", data: { aos: "title-underline" } do
              title_tag = content_tag(:h3, title, class: "section-title", style: "font-family: 'Playfair Display', serif; font-size: 2rem; position: relative; display: inline-block;")
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
        image_col = content_tag :div, class: "col-12 col-md-6 #{image_order} d-flex", data: { scroll_reveal: true } do
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
      classes = ["nav-item text-center mx-3 my-1"]
      
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

  def public_card(
    icon:, 
    title:, 
    content: nil, 
    description: nil, 
    features: nil,
    theme: "dark", # "dark" ou "light"
    card_style: "info", # "info", "concept", ou "activity"
    icon_size: "fs-3",
    title_size: "fs-4",
    wrapper_class: nil,
    &block
  )
    # Définir les couleurs selon le thème
    if theme == "dark"
      bg_class = "bg-dark"
      text_class = "text-light"
    else
      bg_class = "bg-light"
      text_class = "text-dark"
    end
    
    # Wrapper optionnel pour info cards
    wrapper = wrapper_class || (card_style == "info" ? "col-sm m-2 p-0 w-100" : "")
    
    # Styles pour effet hover
    hover_style = "transition: all 0.3s ease; cursor: pointer;"
    
    content_tag :div, class: wrapper do
      content_tag :div, 
        class: "#{bg_class} #{text_class} rounded-1 p-4 h-100 d-flex flex-column shadow-sm", 
        style: hover_style,
        onmouseover: "this.style.transform='translateY(-8px)'; this.classList.replace('shadow-sm', 'shadow-lg')",
        onmouseout: "this.style.transform='translateY(0)'; this.classList.replace('shadow-lg', 'shadow-sm')" do
        sections = []
        
        # Icon section
        if icon.present?
          icon_section = content_tag(:div, class: "#{card_style == 'info' ? 'text-center' : ''} mb-#{card_style == 'activity' ? '4' : '3'}") do
            if card_style == "info"
              icon_tag = content_tag(:i, nil, class: "bi bi-#{icon} #{icon_size} me-2")
              title_tag = content_tag(:span, title, class: "fw-bold #{title_size}")
              (icon_tag + title_tag).html_safe
            else
              content_tag(:div, class: "#{'text-center' if card_style == 'concept'}") do
                content_tag(:i, nil, class: "bi bi-#{icon} fs-1")
              end
            end
          end
          sections << icon_section
        end
        
        # Title section (sauf pour info card où il est avec l'icône)
        if card_style != "info" && title.present?
          title_class = card_style == "activity" ? "h3" : "h4"
          title_section = content_tag(:h3, title, class: "#{title_class} fw-bold mb-3 #{card_style == 'concept' ? 'text-center' : ''}")
          sections << title_section
        end
        
        # Description
        if description.present?
          desc_section = content_tag(:p, description, class: "mb-4 opacity-75")
          sections << desc_section
        end
        
        # Content (pour info cards)
        if content.present?
          content_section = content_tag(:div) do
            content.to_s.html_safe
          end
          sections << content_section
        end
        
        # Features list
        if features.present? && features.any?
          features_section = content_tag(:ul, class: "list-unstyled") do
            features.map do |feature|
              content_tag(:li, class: "mb-2") do
                concat content_tag(:i, nil, class: "bi bi-check-circle-fill me-2")
                concat feature
              end
            end.join.html_safe
          end
          sections << features_section
        end
        
        # Custom content from block
        if block_given?
          custom_content = capture(&block)
          sections << custom_content
        end
        
        sections.join.html_safe
      end
    end
  end


  # ============================================================================
  # NOUVEAUX HELPERS GÉNÉRIQUES POUR CONTENU STRUCTURÉ
  # ============================================================================

  # Helper générique pour créer une section de contenu (FAQ, legal, etc.)
  # Remplace et unifie faq_section et legal_section
  def content_section(id:, icon:, title:, accordion_id: nil, alert: nil, theme: "dark", &block)
    content_tag :section, id: id, class: "my-5", "data-scroll-reveal": true do
      content_tag :div, class: "" do
        sections = []
        
        # Title with icon
        title_html = content_tag(:h2, class: "h3 fw-bold mb-4 text-light") do
          concat content_tag(:i, nil, class: "bi bi-#{icon} text-light me-2")
          concat title
        end
        sections << title_html
        
        # Optional alert
        if alert
          alert_class = alert[:type] == :warning ? "alert-warning" : "alert-info"
          alert_style = alert[:type] == :warning ? 
            "background: rgba(255, 193, 7, 0.15); border: 1px solid rgba(255, 193, 7, 0.3);" :
            "background: rgba(255, 255, 255, 0.1); border: 1px solid rgba(255, 255, 255, 0.2);"
          icon_class = alert[:type] == :warning ? "text-warning" : "text-light"
          
          alert_html = content_tag(:div, class: "alert #{alert_class} mb-4", style: alert_style) do
            concat content_tag(:i, nil, class: "bi bi-#{alert[:icon]} #{icon_class} me-2")
            concat content_tag(:small, alert[:text], class: "text-light")
          end
          sections << alert_html
        end
        
        # Content wrapper (accordion or simple content)
        if accordion_id.present?
          # Accordion mode (for FAQ-style content)
          content_html = content_tag(:div, class: "accordion", id: accordion_id) do
            capture(&block) if block_given?
          end
        else
          # Simple content mode (for legal/article-style content)
          content_html = capture(&block) if block_given?
        end
        sections << content_html
        
        sections.join.html_safe
      end
    end
  end

  # Helper générique pour créer un item d'accordéon
  # Version améliorée et plus flexible de faq_item
  def collapsible_item(id:, parent_id:, title:, expanded: false, theme: "dark", &block)
    item_id = "#{parent_id}_#{id}"
    heading_id = "heading_#{item_id}"
    collapse_id = "collapse_#{item_id}"
    
    # Theme colors
    bg_class = theme == "dark" ? "bg-black" : "bg-light"
    text_class = theme == "dark" ? "text-light" : "text-dark"
    border_class = theme == "dark" ? "border-dark" : "border-dark"
    
    content_tag :div, class: "accordion-item #{bg_class} #{border_class}" do
      # Accordion header
      header = content_tag(:h2, class: "accordion-header", id: heading_id) do
        button_class = "accordion-button #{expanded ? '' : 'collapsed'} #{bg_class} #{text_class}"
        button_style = theme == "dark" ? "color: #fff !important;" : ""
        content_tag(:button, 
          class: button_class,
          type: "button",
          style: button_style,
          "data-bs-toggle": "collapse",
          "data-bs-target": "##{collapse_id}",
          "aria-expanded": expanded ? "true" : "false",
          "aria-controls": collapse_id) do
          title
        end
      end
      
      # Accordion collapse
      collapse = content_tag(:div,
        id: collapse_id,
        class: "accordion-collapse collapse #{expanded ? 'show' : ''}",
        "aria-labelledby": heading_id,
        "data-bs-parent": "##{parent_id}") do
        content_tag(:div, class: "accordion-body #{bg_class} #{text_class} opacity-75") do
          capture(&block) if block_given?
        end
      end
      
      (header + collapse).html_safe
    end
  end

  # Helper générique pour créer un article/bloc de contenu numéroté
  # Version améliorée de legal_article avec plus d'options
  def content_article(number: nil, title:, content: nil, theme: "light", &block)
    content_tag :div, class: "my-4" do
      sections = []
      
      # Title with optional number
      title_text = number.present? ? "Article #{number} - #{title}" : title
      title_html = content_tag(:h4, title_text, class: "h5 fw-bold mt-4 mb-3 text-light")
      sections << title_html
      
      # Content (either from parameter or block)
      if content.present?
        content_html = content_tag(:p, content.html_safe, class: "text-light opacity-75")
        sections << content_html
      elsif block_given?
        custom_content = content_tag(:div, class: "text-light opacity-75") do
          capture(&block)
        end
        sections << custom_content
      end
      
      sections.join.html_safe
    end
  end

  # Helper pour créer une liste de liens de navigation rapide
  def quick_nav_links(links:, columns: 3)
    content_tag :div, class: "concept-card my-4", "data-scroll-reveal": true do
      title = content_tag(:h5, "Navigation rapide", class: "fw-bold mb-3 text-light")
      
      nav_content = content_tag(:div, class: "row g-3") do
        links.map do |link|
          content_tag(:div, class: "col-md-#{12/columns}") do
            link_to link[:url], class: "text-decoration-none text-light" do
              concat content_tag(:i, nil, class: "bi bi-chevron-right me-2")
              concat link[:text]
            end
          end
        end.join.html_safe
      end
      
      (title + nav_content).html_safe
    end
  end

  # Helper pour créer une grille de boutons de navigation par catégorie
  def category_nav_buttons(categories:)
    content_tag :div, class: "my-4", "data-scroll-reveal": true do
      title = content_tag(:h5, "Navigation par catégorie", class: "fw-bold mb-3 text-center text-light")
      
      buttons = content_tag(:div, class: "d-flex flex-wrap justify-content-center gap-2") do
        categories.map do |cat|
          link_to cat[:url], class: "btn btn-outline-light btn-sm" do
            concat content_tag(:i, nil, class: "bi bi-#{cat[:icon]} me-1")
            concat cat[:text]
          end
        end.join.html_safe
      end
      
      (title + buttons).html_safe
    end
  end

  # Helper pour générer les boutons de panier (cabine ou shop) avec style commun
  def cart_button_for(produit, type: :shop, button_class: "")
    turbo_frame_tag "produit_#{produit.id}_button" do
      card_footer_class = "card-footer p-0 w-100"
      
      content_tag :div, class: card_footer_class do
        case type
        when :cabine
          render_cabine_button(produit, button_class)
        when :shop
          render_shop_button(produit, button_class)
        end
      end
    end
  end

  private

  def render_cabine_button(produit, extra_class = "")
    if session[:cabine_cart].include?(produit.id)
      button_to cabine_remove_product_path(produit), method: :delete,
          class: "btn btn-sm w-100 btn-outline-danger #{extra_class}" do
        (content_tag(:i, nil, class: "bi bi-bag-x me-2") + "Retirer de la cabine").html_safe
      end
    elsif session[:cabine_cart].size >= 10
      content_tag :button, type: "button", class: "btn btn-sm w-100 btn-secondary #{extra_class}", disabled: true do
        (content_tag(:i, nil, class: "bi bi-exclamation-triangle me-2") + "Limite atteinte (10 produits max)").html_safe
      end
    else
      button_to cabine_add_product_path(produit),
          class: "btn btn-sm w-100 btn-light hover-lift public-btn-border-radius #{extra_class}" do
        (content_tag(:i, nil, class: "bi bi-bag-plus me-2") + "Ajouter à la cabine").html_safe
      end
    end
  end

  def render_shop_button(produit, extra_class = "")
    if session[:cart].include?(produit.id)
      button_to remove_from_cart_path(produit), method: :delete,
          class: "btn btn-sm w-100 btn-secondary #{extra_class}" do
        (content_tag(:i, nil, class: "bi bi-bag-x me-2") + "Retirer du panier").html_safe
      end
    else
      button_to add_to_cart_path(produit),
          class: "btn btn-sm w-100 btn-light hover-lift public-btn-border-radius #{extra_class}" do
        (content_tag(:i, nil, class: "bi bi-bag-plus me-2") + "Ajouter au panier").html_safe
      end
    end
  end

end
