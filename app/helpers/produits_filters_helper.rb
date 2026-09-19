module ProduitsFiltersHelper
  SEARCH_QUERY_FIELDS = %i[
    nom_or_reffrs_or_handle_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_or_fournisseur_nom_cont
    id_eq
  ].freeze

  FILTER_PARAM_KEYS = %i[
    filter_taille filter_couleur filter_categorie filter_type_produit
    filter_statut filter_fournisseur filter_mode filter_prix
  ].freeze

  # Lit les filtres depuis la query string
  # et on ne propage que ce qu'il faut pour reconstruire les URLs de filtre.
  def produits_filter_params(exclude: nil, include_sort: false)
    keys = FILTER_PARAM_KEYS.dup
    keys << :sort if include_sort
    keys -= [exclude.to_sym] if exclude.present?
    request.query_parameters.symbolize_keys.slice(*keys)
  end

  FILTER_DROPDOWN_ITEM_NAME_LENGTH = 40

  def produits_active_filters_count
    FILTER_PARAM_KEYS.count { |k| params[k].present? }
  end

  def filter_dropdown(label:, icon:, param_key:, collection: nil, model: nil, current_params: {}, all_label: nil, columns: nil,
                      always_show_label: false, id_suffix: nil, link_data: {}, multiple: false, keep_label: nil)
    keep_label = multiple if keep_label.nil?
    selected_values = Admin::ProduitListingFilters.normalize_filter_values(params[param_key])
    selected_value = multiple ? selected_values.first : params[param_key]
    item_opts = ->(**html) do
      if link_data.present?
        html[:data] = (html[:data] || {}).merge(link_data)
      end
      html
    end
    selected_label =
    if multiple && selected_values.size > 1
      "#{label} · #{selected_values.size}"
    elsif selected_value.present? && model
      case param_key
      when :filter_taille, :filter_categorie, :filter_couleur, :filter_fournisseur, :filter_type_produit
        selected_value.to_s == "na" ? "NA" : filter_dropdown_record_label(model, selected_value)
      else
        filter_dropdown_record_label(model, selected_value)
      end
    
    elsif selected_value.present? && param_key == :filter_statut
      case selected_value
      when "true" then "actif"
      when "false" then "archivé"
      when "na" then "sans statut"
      else selected_value.to_s
      end
    elsif selected_value.present? && param_key == :filter_mode
      selected_value == "analyse" ? "analyse" : "défaut"
    elsif selected_value.present? && param_key == :filter_prix
      if selected_value == "na"
        "NA"
      else
        "< #{custom_currency_no_decimals_format(selected_value)}"
      end
    end

    selected_title =
      if multiple && selected_values.size > 1 && model
        selected_values.map { |id| id == "na" ? "NA" : filter_dropdown_record_label(model, id) }.compact.join(", ")
      elsif selected_label.present?
        selected_label.to_s
      end

    toggle_id = id_suffix.present? ? "#{param_key}Dropdown_#{id_suffix}" : "#{param_key}Dropdown"
    toggle_data = { bs_toggle: "dropdown" }
    toggle_data[:bs_auto_close] = "outside" if multiple

    content_tag(:div, class: "dropdown") do
      # Button
      concat(
        content_tag(:button,
          class: "btn btn-sm btn-outline-secondary dropdown-toggle d-inline-flex align-items-center gap-1 min-w-0",
          type: "button",
          id: toggle_id,
          data: toggle_data,
          aria: { expanded: false },
          title: selected_title) do
          button_parts = []
          button_parts << tag.i(class: "#{icon} flex-shrink-0", aria: { hidden: true })

          if selected_label.present? && !keep_label
            button_parts << content_tag(:span, selected_label,
              class: "text-truncate text-start",
              style: "max-width: 11rem")
          else
            label_span_class = always_show_label ? "text-start" : "text-start d-none d-md-inline"
            button_label =
              if keep_label && selected_values.size > 1
                "#{label.pluralize} #{selected_values.size}"
              else
                label
              end
            button_parts << content_tag(:span, button_label, class: label_span_class)
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
                    **item_opts.call(class: produits_filter_dropdown_item_class(active))
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
                  **item_opts.call(class: produits_filter_dropdown_item_class(selected_value.blank?))
                )
              end
            )

            concat(
              content_tag(:li) do
                link_to(
                  "NA",
                  url_for(current_params.merge(param_key => "na")),
                  **item_opts.call(class: produits_filter_dropdown_item_class(selected_value == "na"))
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
                    **item_opts.call(class: produits_filter_dropdown_item_class(active))
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
                  **item_opts.call(
                    class: multiple ? "dropdown-item small" : produits_filter_dropdown_item_class(selected_values.empty?)
                  )
                )
              end
            )
          
            if [:filter_taille, :filter_categorie, :filter_couleur, :filter_statut, :filter_fournisseur, :filter_type_produit].include?(param_key)
              concat(
                content_tag(:li) do
                  filter_dropdown_choice_link(
                    label: "NA",
                    url: filter_dropdown_choice_url(current_params, param_key, "na", selected_values, multiple: multiple),
                    active: selected_values.include?("na"),
                    multiple: multiple,
                    item_opts: item_opts
                  )
                end
              )
            end
            
          
            collection.each do |item|
              id_s = item.id.to_s
              active = selected_values.include?(id_s)
              nom = filter_dropdown_item_name(item)
              display = truncate(nom, length: FILTER_DROPDOWN_ITEM_NAME_LENGTH, omission: "…")
              concat(
                content_tag(:li) do
                  filter_dropdown_choice_link(
                    label: display,
                    url: filter_dropdown_choice_url(current_params, param_key, item, selected_values, multiple: multiple),
                    active: active,
                    multiple: multiple,
                    item_opts: item_opts,
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
                    **item_opts.call(class: produits_filter_dropdown_item_class(active))
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

    request_q = request.query_parameters["q"]

    search_payload =
      if request_q.present?
        ActionController::Parameters.new(q: request_q).permit(q: SEARCH_QUERY_FIELDS)[:q]&.to_h
      end

    merged_params[:q] = search_payload if search_payload.present?

    merged_params.delete_if do |_, value|
      value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end

    merged_params
  end

  def produits_listing_path_params(page: nil)
    params_hash = listing_params_with_search(produits_filter_params(include_sort: true))
    params_hash[:page] = page if page.present?
    params_hash
  end

  def produits_turbo_stream_path(page: nil)
    admin_produits_path(produits_listing_path_params(page: page).merge(format: :turbo_stream))
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

  def filter_dropdown_item_name(item)
    if item.respond_to?(:full_name)
      item.full_name.presence || item.try(:nom).to_s
    else
      item.nom.to_s
    end
  end

  def filter_dropdown_record_label(model, id)
    record = model.find_by(id: id)
    return nil unless record

    filter_dropdown_item_name(record)
  end

  def filter_dropdown_choice_url(current_params, param_key, item, selected_values, multiple:)
    id = item.respond_to?(:id) ? item.id.to_s : item.to_s
    if multiple
      next_values = selected_values.include?(id) ? selected_values - [id] : selected_values + [id]
      url_for(current_params.merge(param_key => next_values.presence))
    else
      url_for(current_params.merge(param_key => item))
    end
  end

  def filter_dropdown_choice_link(label:, url:, active:, multiple:, item_opts:, title: nil)
    item_class =
      if multiple
        class_names("dropdown-item", "small", "d-flex align-items-center gap-2", "is-selected" => active)
      else
        produits_filter_dropdown_item_class(active)
      end
    opts = item_opts.call(class: item_class, title: title)
    if multiple
      link_to(url, **opts) do
        safe_join([
          tag.i(
            class: class_names("bi flex-shrink-0", active ? "bi-check-square" : "bi-square"),
            aria: { hidden: true }
          ),
          label
        ], " ")
      end
    else
      link_to(label, url, **opts)
    end
  end
end
