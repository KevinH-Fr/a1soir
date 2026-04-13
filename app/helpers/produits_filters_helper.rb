module ProduitsFiltersHelper
  SEARCH_QUERY_FIELDS = %i[
    nom_or_reffrs_or_handle_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_or_fournisseur_nom_cont
    id_eq
  ].freeze

  FILTER_PARAM_KEYS = %i[
    filter_taille filter_couleur filter_categorie filter_type_produit
    filter_statut filter_fournisseur filter_mode filter_prix
  ].freeze

  FILTER_DROPDOWN_ITEM_NAME_LENGTH = 40

  def produits_active_filters_count
    FILTER_PARAM_KEYS.count { |k| params[k].present? }
  end

  def filter_dropdown(label:, icon:, param_key:, collection: nil, model: nil, current_params: {}, all_label: nil, columns: nil,
                      always_show_label: false, id_suffix: nil)
    selected_value = params[param_key]
    selected_label =
    if selected_value.present? && model
      case param_key
      when :filter_taille, :filter_categorie, :filter_couleur, :filter_fournisseur, :filter_type_produit
        selected_value == "na" ? "NA" : model.find_by(id: selected_value)&.nom
      else
        model.find_by(id: selected_value)&.nom
      end
    
    elsif selected_value.present? && param_key == :filter_statut
      selected_value == "true" ? "actif" : "archivé"
    elsif selected_value.present? && param_key == :filter_mode
      selected_value == "analyse" ? "analyse" : "défaut"
    elsif selected_value.present? && param_key == :filter_prix
      if selected_value == "na"
        "NA"
      else
        "< #{custom_currency_no_decimals_format(selected_value)}"
      end
    end

    toggle_id = id_suffix.present? ? "#{param_key}Dropdown_#{id_suffix}" : "#{param_key}Dropdown"

    content_tag(:div, class: "dropdown") do
      # Button
      concat(
        content_tag(:button,
          class: "btn btn-sm btn-outline-secondary dropdown-toggle d-inline-flex align-items-center gap-1 min-w-0",
          type: "button",
          id: toggle_id,
          data: { bs_toggle: "dropdown" },
          aria: { expanded: false },
          title: (selected_label.present? ? selected_label.to_s : nil)) do
          button_parts = []
          button_parts << tag.i(class: "#{icon} flex-shrink-0", aria: { hidden: true })

          if selected_label.present?
            button_parts << content_tag(:span, selected_label,
              class: "text-truncate text-start",
              style: "max-width: 11rem")
          else
            label_span_class = always_show_label ? "text-start" : "text-start d-none d-md-inline"
            button_parts << content_tag(:span, label, class: label_span_class)
          end

          safe_join(button_parts)
        end
      )

      # Dropdown menu
      menu_classes = %w[dropdown-menu shadow-sm]
      if columns.present? && columns.to_i > 1
        menu_classes << "multi-column" << "columns-#{columns.to_i}"
      end

      concat(
        content_tag(:ul, class: menu_classes.join(" "), aria: { labelledby: toggle_id }) do
  
        if param_key == :filter_mode
            [
              { value: "analyse", label: "Analyse" },
              { value: "défaut", label: "Défaut" }
            ].each do |option|
              active = selected_value == option[:value]
              concat(
                content_tag(:li) do
                  link_to(
                    option[:label],
                    url_for(current_params.merge(param_key => option[:value])),
                    class: produits_filter_dropdown_item_class(active)
                  )
                end
              )
            end
          elsif param_key == :filter_prix
            tranches_prix = [50, 100, 200, 500, 1000]

            concat(
              content_tag(:li) do
                link_to(
                  "Tous",
                  url_for(current_params.merge(param_key => nil)),
                  class: produits_filter_dropdown_item_class(selected_value.blank?)
                )
              end
            )

            concat(
              content_tag(:li) do
                link_to(
                  "NA",
                  url_for(current_params.merge(param_key => "na")),
                  class: produits_filter_dropdown_item_class(selected_value == "na")
                )
              end
            )

            tranches_prix.each do |prix|
              label = "< #{custom_currency_no_decimals_format(prix)}"
              active = selected_value.to_s == prix.to_s
              concat(
                content_tag(:li) do
                  link_to(
                    label.html_safe,
                    url_for(current_params.merge(param_key => prix)),
                    class: produits_filter_dropdown_item_class(active)
                  )
                end
              )
            end

          elsif collection
            concat(
              content_tag(:li) do
                link_to(
                  all_label || "Tous",
                  url_for(current_params.merge(param_key => nil)),
                  class: produits_filter_dropdown_item_class(selected_value.blank?)
                )
              end
            )
          
            if [:filter_taille, :filter_categorie, :filter_couleur, :filter_statut, :filter_fournisseur, :filter_type_produit].include?(param_key)
              concat(
                content_tag(:li) do
                  link_to(
                    "NA",
                    url_for(current_params.merge(param_key => "na")),
                    class: produits_filter_dropdown_item_class(selected_value == "na")
                  )
                end
              )
            end
            
          
            collection.each do |item|
              active = selected_value.to_s == item.id.to_s
              nom = item.nom.to_s
              display = truncate(nom, length: FILTER_DROPDOWN_ITEM_NAME_LENGTH, omission: "…")
              concat(
                content_tag(:li) do
                  link_to(
                    display,
                    url_for(current_params.merge(param_key => item)),
                    class: produits_filter_dropdown_item_class(active),
                    title: nom
                  )
                end
              )
            end
          
          elsif param_key == :filter_statut
            [
              { value: "true", label: "actif" },
              { value: "false", label: "archivé" }
            ].each do |option|
              active = selected_value == option[:value]
              concat(
                content_tag(:li) do
                  link_to(
                    option[:label],
                    url_for(current_params.merge(param_key => option[:value])),
                    class: produits_filter_dropdown_item_class(active)
                  )
                end
              )
            end
          end
        end
      )
    end
  end

  def listing_params_with_search(base_params)
    merged_params = base_params.to_h

    permitted_q = params.permit(q: SEARCH_QUERY_FIELDS)[:q]
    request_q = request.query_parameters["q"]

    search_payload =
      if permitted_q.present?
        permitted_q.to_h
      elsif request_q.present?
        request_q
      end

    merged_params[:q] = search_payload if search_payload.present?

    merged_params.delete_if do |_, value|
      value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end

    merged_params
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
          class: "btn btn-sm btn-outline-primary dropdown-toggle d-inline-flex align-items-center gap-1 min-w-0",
          type: "button",
          id: "sortDropdown",
          data: { bs_toggle: "dropdown" },
          aria: { expanded: false },
          title: (current_label.presence)
        ) do
          parts = []
          parts << tag.i(class: "bi bi-sort-up-alt flex-shrink-0", aria: { hidden: true })

          if current_label
            parts << content_tag(:span, current_label,
              class: "text-truncate text-start",
              style: "max-width: 11rem")
          else
            parts << content_tag(:span, "Trier", class: "text-start d-none d-md-inline")
          end

          safe_join(parts)
        end
      )

      concat(
        content_tag(:ul, class: "dropdown-menu shadow-sm", aria: { labelledby: "sortDropdown" }) do
          concat(
            content_tag(:li) do
              link_to(
                "Par défaut",
                url_for(current_params.merge(sort: nil)),
                class: produits_filter_dropdown_item_class(params[:sort].blank?)
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
                  class: produits_filter_dropdown_item_class(active)
                )
              end
            )
          end
        end
      )
    end
  end

  private

  def produits_filter_dropdown_item_class(active)
    ["dropdown-item", "small", ("active" if active)].compact.join(" ")
  end
end
