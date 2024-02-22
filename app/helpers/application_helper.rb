module ApplicationHelper

    def custom_currency_format(amount)
        number_to_currency(amount, precision: 2, unit: "€", format: "%n %u", delimiter: " ")
    end

    def custom_badge(icon_class, text, color, value)
        content_tag(:div, class: "badge bg-#{color} mx-2 fs-6") do
          concat content_tag(:i, '', class: "fa #{icon_class} me-1")
          concat " #{text}"
          concat " #{value}"
        end
    end

    def custom_badge_boolean(text, value)
        color = (value != 0) ? "danger" : "success"
        content_tag(:div, class: "badge bg-#{color} mx-2 fs-6") do
          concat " #{text}"
          concat " #{custom_currency_format(value)}"
        end
    end
      

end
