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

end
