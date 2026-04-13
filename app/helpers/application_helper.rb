module ApplicationHelper

  include Pagy::Frontend
  
  CLOUDINARY_BASE_IMAGE_URL = "https://res.cloudinary.com/dukne3lhz/image/upload".freeze
  CLOUDINARY_BASE_VIDEO_URL = "https://res.cloudinary.com/dukne3lhz/video/upload".freeze

  def custom_currency_format(amount)
    precision = amount.to_f == amount.to_i ? 0 : 2
    number_to_currency(amount, precision: precision, unit: "€", format: "%n %u", delimiter: " ")
  end


  def custom_currency_no_decimals_format(amount)
      number_to_currency(amount, precision: 0, unit: "€", format: "%n %u", delimiter: " ")
  end

  def custom_badge(icon_class, text, color, bold, value)
    content_tag(:div,
      class: "badge lighter-beige-colored fw-normal #{bold} bg-#{color} m-1 fs-6 shadow-sm text-dark text-break",
      style: "white-space: normal;"
    ) do
      if icon_class.present?
        concat content_tag(:i, '', class: "fa #{icon_class} me-1")
      end
      concat " #{text}"
      concat " #{value}"
    end
  end

  # Helper pour obtenir l'icône Bootstrap selon le statut d'une demande cabine
  def statut_demande_cabine_icon(statut)
    case statut
    when "brouillon"
      "bi-file-earmark-text"
    when "soumis"
      "bi-hourglass-split text-warning"
    when "confirme", "confirmé"
      "bi-check-circle text-success"
    when "annule", "annulé"
      "bi-x-circle text-danger"
    else
      "bi-question-circle"
    end
  end

  # Helper pour afficher le badge de statut d'une demande cabine avec icône
  def badge_statut_demande_cabine(statut)
    return "" unless statut.present?
    
    content_tag(:div, 
      class: "badge lighter-beige-colored fw-normal m-1 fs-6 shadow-sm text-dark text-break d-inline-flex align-items-center", 
      style: "white-space: normal;") do
      concat content_tag(:i, "", class: "bi #{statut_demande_cabine_icon(statut)} me-1")
      concat content_tag(:span, statut)
    end
  end
  
    def custom_badge_boolean(text, value)
        color = (value != 0) ? "danger" : "success"
        content_tag(:div, class: "badge bg-#{color} me-1 small") do
          concat " #{text}"
          concat " #{custom_currency_format(value)}"
        end
    end

    # Pastilles KPI compactes (bandeau sombre fiche commande) — utilitaires Bootstrap uniquement.
    # icon: nom Bootstrap Icons sans préfixe (ex. "currency-euro") — sur mobile (< md), l’icône remplace le libellé.
    def synthese_kpi_chip(label, value, icon: nil)
      title = "#{label} : #{value}"
      label_classes = ["text-uppercase", "small", "text-white-50", "fw-semibold", "lh-1", "text-nowrap"]
      label_classes += %w[d-none d-md-inline] if icon.present?

      parts = []
      if icon.present?
        parts << tag.i(class: "bi bi-#{icon} flex-shrink-0 d-md-none opacity-90", aria: { hidden: true })
      end
      parts << tag.span(label, class: label_classes.join(" "))
      parts << tag.span(value.to_s, class: "fw-semibold text-white lh-sm font-monospace small")

      content_tag(:span,
        class: "admin-synthese-kpi-chip d-inline-flex align-items-center gap-1 gap-md-2 px-1 px-md-2 py-0 py-md-1 rounded-2 border border-light border-opacity-25 bg-white bg-opacity-10 text-light",
        title: title,
        aria: { label: title }) do
        safe_join(parts)
      end
    end

    # Conteneur des pastilles KPI (bandeau section) — une ligne sur mobile, wrap à partir de md.
    def admin_synthese_kpi_strip(&block)
      content_tag(:div,
        class: "admin-synthese-kpi-strip d-flex flex-nowrap flex-md-wrap gap-1 gap-md-2 align-items-center justify-content-end mw-100 min-w-0 flex-shrink-0") do
        yield
      end
    end

    # CTA jaune « + Nouveau » (bandeaux `card_main_model`). Texte masqué sous md — aligné au mobile admin (768px).
    def admin_bandeau_nouveau_cta(url, **options)
      aria = { label: "Nouveau" }.merge(options.delete(:aria) || {})
      extra = options.delete(:class)
      css = %w[btn btn-sm btn-warning fw-bold d-inline-flex align-items-center gap-1 flex-shrink-0]
      css << extra if extra.present?
      link_to url, **options.merge(class: css.join(" "), aria: aria) do
        safe_join([
          tag.i(class: "bi bi-plus-lg", aria: { hidden: true }),
          tag.span("Nouveau", class: "d-none d-md-inline small fw-bold"),
        ])
      end
    end

    # Contenu (icône + texte) du lien « Détails » pour panneaux collapse — le <a> reste dans la vue.
    def admin_collapse_details_button_content(label: "Détails")
      safe_join([
        tag.i(class: "bi bi-chevron-down me-1", style: "font-size: 0.7rem;"),
        label
      ])
    end

    def field_with_label(text, value, icon_class: nil)
      if value.present?
        classes = %w[badge lighter-beige-colored text-dark fw-normal fs-6 mb-1]
        classes += %w[d-inline-flex align-items-center] if icon_class.present?

        content_tag(:div, class: classes.join(" ")) do
          if icon_class.present?
            icon_full = icon_class.to_s.start_with?("bi-") ? "bi #{icon_class}" : "bi bi-#{icon_class}"
            concat tag.i(class: "#{icon_full} me-1 opacity-75 flex-shrink-0", aria: { hidden: true })
          end
          concat " #{text}"
          concat " #{value}"
        end
      end
    end

    def colored_value_format(amount)
      css_style = amount.to_i > 0 ? 'color: red;' : 'color: green;'
      content_tag(:span, custom_currency_format(amount), style: css_style)
    end
    

    def color_icon(couleur)
      content_tag(:i, '', class: "bi bi-circle-fill mx-1", style: "color: #{couleur.couleur_code}")
    end

    def icon_true_field_with_label(text, value)
      if value
        content_tag(:p, class: "text-start badge text-dark mx-0 p-0 fs-6") do
          concat " #{text}"
          concat content_tag(:i, "", class: "fas text-success bi-check-circle ms-1")
        end
      end
    end

    def extract_ids(objects)
      Array.wrap(objects).pluck(:id)
    end
    
    def format_date_in_french(date)
      I18n.l(date, locale: :fr)  # Format the date in French using I18n
    end

    def no_photo_url
      'https://res.cloudinary.com/dukne3lhz/image/upload/v1738665309/no_photo_black_p8wyfh.png'
    end

  def cloudinary_image(public_id, width:, alt:, **options)
    transformation = "q_auto,f_auto,w_#{width}"
    url = "#{CLOUDINARY_BASE_IMAGE_URL}/#{transformation}/#{public_id}"
    image_tag(url, { alt: alt }.merge(options))
  end

  def cloudinary_video_url(attachment, width: 800, quality: "auto")
    key = attachment.blob.key
    transformation = "q_#{quality},w_#{width},vc_auto,f_auto"
    "#{CLOUDINARY_BASE_VIDEO_URL}/#{transformation}/#{key}"
  end

  # Génère un image_tag optimisé via Cloudinary à partir d'un attachment ActiveStorage.
  # Fallback vers image_tag classique si l'argument est un chemin string (ex: no_photo).
  def cloudinary_attachment_image(attachment, width: 800, alt:, **options)
    if attachment.respond_to?(:blob)
      key = attachment.blob.key
      transformation = "q_auto,f_auto,w_#{width}"
      url = "#{CLOUDINARY_BASE_IMAGE_URL}/#{transformation}/#{key}"
      image_tag(url, { alt: alt }.merge(options))
    else
      image_tag(attachment, { alt: alt }.merge(options))
    end
  end

    def google_calendar_embed_url
      if Rails.env.development? || Rails.env.test?
        # URL pour l'environnement local (développement/test)
        "https://calendar.google.com/calendar/embed?src=kevin.hoffman.france%40gmail.com&ctz=Europe%2FParis"
      else
        # URL pour la production
        "https://calendar.google.com/calendar/embed?height=600&wkst=2&ctz=Europe%2FParis&showPrint=0&showCalendars=0&mode=WEEK&src=Y29udGFjdEBhMXNvaXIuY29t&src=ZnIuZnJlbmNoI2hvbGlkYXlAZ3JvdXAudi5jYWxlbmRhci5nb29nbGUuY29t&color=%23039BE5&color=%230B8043"
      end
    end

    def simple_image_text_section(image_path:, title:, text:, active: false, image_position: "center", button_text: nil, button_url: nil)
      content_tag(:div, class: "carousel-item #{active ? 'active' : ''}") do
        content_tag(:div, class: "container-fluid px-0") do
          content_tag(:div, class: "position-relative", style: "height: 90vh; overflow: hidden;") do
            concat image_tag(
              image_path,
              class: "img-fluid w-100 h-100",
              style: "object-fit: cover; object-position: #{image_position};",
              alt: title,
              width: 1920,
              height: 1080,
              loading: "lazy"
            )
            concat(
              content_tag(:div, 
                class: "position-absolute top-0 start-0 w-100 h-100 d-flex align-items-center justify-content-center",
                style: "background: linear-gradient(to bottom, rgba(0,0,0,0.4), rgba(0,0,0,0.6));") do
                content_tag(:div, class: "text-center text-light px-4", style: "max-width: 700px;") do
                  concat(
                    content_tag(:div, class: "section-title-wrapper mb-4") do
                      content_tag(:h3, 
                        class: "text-light section-title", 
                        style: "font-family: 'Playfair Display', serif; font-size: 2.2rem; position: relative; display: inline-block;") do
                        concat title
                      end
                    end
                  )
                  concat content_tag(:p, text, class: "fs-6 mb-4", style: "line-height: 1.8;")
                  if button_text.present? && button_url.present?
                    concat link_to(button_text, button_url, class: "btn btn-light px-4 rounded-0")
                  end
                end
              end
            )
          end
        end
      end
    end

  # Classes Bootstrap partagées : contenu du collapse « Nouveau » (padding sur l’intérieur, pas sur .collapse — twbs/bootstrap#12093).
  def admin_collapse_nouveau_inner_classes
    "py-1 m-0"
  end

  # Pile de cartes sous bandeau ou sous collapse replié : reprend pt-1 + m-0 du bloc inner pour le même rythme que les sections type Paiements.
  def admin_list_stack_classes
    "#{admin_collapse_nouveau_inner_classes} d-flex flex-column gap-2 pb-2".squish
  end

  # Bloc repliable « Nouveau » (partial `admin/shared/collapse_nouveau`, même logique que `bloc_nouveau`).
  def admin_collapse_nouveau(collapse_id:, target_id:, inner_partial:, **inner_locals)
    render "admin/shared/collapse_nouveau",
           collapse_id: collapse_id,
           target_id: target_id,
           inner_partial: inner_partial,
           inner_locals: inner_locals
  end

end
