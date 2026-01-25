module ApplicationHelper

  include Pagy::Frontend
  
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
      "bi-hourglass-split"
    when "confirme", "confirmé"
      "bi-check-circle"
    when "annule", "annulé"
      "bi-x-circle"
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

    def field_with_label(text, value)
      if value.present?
        content_tag(:div, class: "badge lighter-beige-colored text-dark fw-normal fs-6") do
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
            concat image_tag(image_path, class: "img-fluid w-100 h-100", style: "object-fit: cover; object-position: #{image_position};")
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

end
