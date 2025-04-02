module ProduitsFiltersHelper
  def filter_dropdown(label:, icon:, param_key:, collection: nil, model: nil, current_params: {}, all_label: nil)
    selected_value = params[param_key]
    selected_label =
      if selected_value == "na"
        "NA"
      elsif selected_value.present? && model
        model.find_by(id: selected_value)&.nom
      elsif selected_value.present? && param_key == :filter_statut
        selected_value == "true" ? "actif" : "archivé"
      end

    content_tag(:div, class: "dropdown") do
      # Button
      concat(
        content_tag(:button,
          class: "btn btn-sm btn-outline-secondary dropdown-toggle",
          type: "button",
          id: "#{param_key}Dropdown",
          data: { bs_toggle: "dropdown" },
          aria: { expanded: false }) do

          button_parts = []
          button_parts << tag.i(class: icon, aria: { hidden: true })

          if selected_label.present?
            button_parts << content_tag(:span, "#{label} :", class: "ms-1 d-none d-md-inline")
            button_parts << content_tag(:span, selected_label, class: "ms-1")
          else
            button_parts << content_tag(:span, label, class: "ms-1 d-none d-md-inline")
          end

          safe_join(button_parts)
        end
      )

      # Dropdown menu
      concat(
        content_tag(:ul, class: "dropdown-menu", aria: { labelledby: "#{param_key}Dropdown" }) do
          # "All" option
          concat(
            content_tag(:li) do
              link_to(
                all_label || "Tous",
                url_for(current_params.merge(param_key => nil)),
                class: "dropdown-item #{'fw-bold' if selected_value.blank?}"
              )
            end
          )

          # "NA" option
          concat(
            content_tag(:li) do
              link_to(
                "NA",
                url_for(current_params.merge(param_key => "na")),
                class: "dropdown-item #{'fw-bold' if selected_value == 'na'}"
              )
            end
          )

          if collection
            collection.each do |item|
              active = selected_value.to_s == item.id.to_s
              concat(
                content_tag(:li) do
                  link_to(
                    item.nom,
                    url_for(current_params.merge(param_key => item)),
                    class: "dropdown-item #{'fw-bold' if active}"
                  )
                end
              )
            end
          else
            # Special case for :filter_statut
            %w[true false].each do |value|
              label_text = value == "true" ? "actif" : "archivé"
              active = selected_value == value
              concat(
                content_tag(:li) do
                  link_to(
                    label_text,
                    url_for(current_params.merge(param_key => value)),
                    class: "dropdown-item #{'fw-bold' if active}"
                  )
                end
              )
            end
          end
        end
      )
    end
  end

  def sort_dropdown(current_params)
    options = {
      "Nom (A-Z)" => "name_asc",
      "Nom (Z-A)" => "name_desc",
      "Plus récent" => "created_at_desc",
      "Plus ancien" => "created_at_asc",
      "Prix location (croissant)" => "prixlocation_asc",
      "Prix location (décroissant)" => "prixlocation_desc",
      "Prix vente (croissant)" => "prixvente_asc",
      "Prix vente (décroissant)" => "prixvente_desc"
    }

    current_label = options.key(params[:sort])

    content_tag(:div, class: "dropdown") do
      concat(
        button_tag(
          class: "btn btn-sm btn-outline-primary dropdown-toggle",
          type: "button",
          id: "sortDropdown",
          data: { bs_toggle: "dropdown" },
          aria: { expanded: false }
        ) do
          parts = []
          parts << tag.i(class: "bi bi-sort-up-alt", aria: { hidden: true })

          if current_label
            parts << content_tag(:span, "Trier :", class: "ms-1 d-none d-md-inline")
            parts << content_tag(:span, current_label, class: "ms-1")
          else
            parts << content_tag(:span, "Trier", class: "ms-1 d-none d-md-inline")
          end

          safe_join(parts)
        end
      )

      concat(
        content_tag(:ul, class: "dropdown-menu", aria: { labelledby: "sortDropdown" }) do
          concat(
            content_tag(:li) do
              link_to(
                "Par défaut",
                url_for(current_params.merge(sort: nil)),
                class: "dropdown-item #{'fw-bold' if params[:sort].blank?}"
              )
            end
          )

          options.each do |label, value|
            active = params[:sort] == value
            concat(
              content_tag(:li) do
                link_to(
                  label,
                  url_for(current_params.merge(sort: value)),
                  class: "dropdown-item #{'fw-bold' if active}"
                )
              end
            )
          end
        end
      )
    end
  end
end
