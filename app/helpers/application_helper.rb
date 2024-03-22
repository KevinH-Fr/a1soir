module ApplicationHelper

    def custom_currency_format(amount)
        number_to_currency(amount, precision: 2, unit: "€", format: "%n %u", delimiter: " ")
    end

    def custom_currency_no_decimals_format(amount)
      number_to_currency(amount, precision: 0, unit: "€", format: "%n %u", delimiter: " ")
  end

    def custom_badge(icon_class, text, color, value)
        content_tag(:div, class: "badge bg-#{color} m-1 fs-6") do
          if icon_class.present?
            concat content_tag(:i, '', class: "fa #{icon_class} me-1")
          end
          concat " #{text}"
          concat " #{value}"
        end
    end

    def custom_badge_boolean(text, value)
        color = (value != 0) ? "danger" : "success"
        content_tag(:div, class: "badge bg-#{color} mx-2 fs-6") do
          concat " #{text}"
          concat " #{custom_currency_no_decimals_format(value)}"
        end
    end

    def field_with_label(text, value)
      if value.present?
        content_tag(:div, class: "mx-2 fs-6") do
          concat " #{text}"
          concat " #{value}"
        end
      end
    end
      

end
