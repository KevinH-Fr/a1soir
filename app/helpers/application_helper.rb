module ApplicationHelper

    def custom_currency_format(amount)
        number_to_currency(amount, precision: 2, unit: "€", format: "%n %u", delimiter: " ")
    end

    def custom_badge(icon_class, value)
        content_tag(:div, class: "badge bg-secondary mx-2 fs-6") do
          concat content_tag(:i, '', class: "fa #{icon_class} me-1")
          concat " #{value}"
        end
    end

end
