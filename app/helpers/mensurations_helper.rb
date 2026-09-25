# Champ + libellé : stack moderne par défaut ; group réservé au dock SVG (suffixe cm).
module MensurationsHelper
  CONTROL = "form-control bg-dark text-light mensuration-field__control"
  GROUP_CONTROL = "form-control form-control-sm mensuration-guide__value"
  SELECT = "form-select bg-dark text-light mensuration-field__control"
  GROUP_SELECT = "form-select form-select-sm text-light"
  LABEL = "mensuration-field__label"
  GROUP_LABEL = "input-group-text"

  def mensuration_field_caption(key)
    t("mensurations.fields.#{key}.name", default: "").presence ||
      t("mensurations.fields.#{key}.short").to_s.sub(/\s*\(cm\)\s*\z/i, "")
  end

  def mensuration_field_ruler(key)
    t("mensurations.fields.#{key}.ruler", default: "").presence
  end

  def mensuration_field_example(key)
    t("mensurations.fields.#{key}.example", default: "").presence ||
      t("mensurations.form.measure_ellipsis")
  end

  def mensuration_measure_input_opts(field)
    if field["input"] == "cm"
      {
        type: :number,
        min: field["min"],
        max: field["max"],
        step: field["increment"].presence || 0.5,
        inputmode: "decimal"
      }.compact
    else
      { maxlength: field["maxlength"].presence || 40 }
    end
  end

  def mensuration_labeled_field(name, value, label, type: :text, layout: :stack, **opts)
    id = opts.delete(:id).presence || (name.present? ? sanitize_to_id(name) : nil)
    addon = opts.delete(:addon)
    classes = [(layout == :group ? GROUP_CONTROL : CONTROL), opts.delete(:class)].compact.join(" ")
    field_opts = opts.merge(id: id, class: classes)
    field_opts[:data] = (field_opts[:data] || {}).merge(initial_value: value) if value.present?

    field = case type
            when :tel then telephone_field_tag(name, value, field_opts)
            when :date then date_field_tag(name, value, field_opts)
            when :number then number_field_tag(name, value, field_opts)
            when :textarea then text_area_tag(name, value, field_opts.merge(rows: opts[:rows] || 2))
            else text_field_tag(name, value, field_opts)
            end

    return grouped_control(id, label, field, suffix: addon) if layout == :group

    stacked_control(id, label, field)
  end

  def mensuration_labeled_select(name, option_tags, label, layout: :stack, selected_value: nil, **opts)
    id = opts.delete(:id).presence || sanitize_to_id(name)
    classes = [(layout == :group ? GROUP_SELECT : SELECT), opts.delete(:class)].compact.join(" ")

    field_opts = opts.merge(id: id, class: classes)
    field_opts[:data] = (field_opts[:data] || {}).merge(initial_value: selected_value) if selected_value.present?
    field = select_tag(name, option_tags, field_opts)
    return grouped_control(id, label, field) if layout == :group

    stacked_control(id, label, field)
  end

  # Pastille admin (collapse / listes compactes).
  def mensuration_measure_chip(field, value)
    key = field["key"]
    display = mensuration_measure_display(field, value)
    short = t("mensurations.fields.#{key}.short", locale: :fr)
    full = t("mensurations.fields.#{key}.admin", locale: :fr)
    wide = field["input"] == "textarea"

    content_tag(:div,
      class: ["mensuration-admin-fiche__cell", ("mensuration-admin-fiche__cell--wide" if wide)].compact.join(" "),
      title: full) do
      safe_join([
        content_tag(:span, short, class: "mensuration-admin-fiche__cell-label"),
        content_tag(:span, display, class: "mensuration-admin-fiche__cell-value")
      ])
    end
  end

  # Ligne fiche sheet (écran = impression) : libellé | valeur.
  def mensuration_sheet_measure_row(field, value)
    key = field["key"]
    display = mensuration_measure_display(field, value)
    label = t("mensurations.fields.#{key}.name", locale: :fr, default: "").presence ||
            t("mensurations.fields.#{key}.short", locale: :fr).to_s.sub(/\s*\(cm\)\s*\z/i, "")
    wide = field["input"] == "textarea"

    content_tag(:div,
      class: ["mensuration-sheet-doc__row", ("mensuration-sheet-doc__row--wide" if wide)].compact.join(" ")) do
      safe_join([
        content_tag(:dt, label),
        content_tag(:dd, display)
      ])
    end
  end

  def mensuration_sheet_meta_row(label, value, wide: false)
    return if value.blank?

    wide ||= label.to_s.match?(/\A(Adresse|E-mail|Email)\z/i) || value.to_s.length > 28

    content_tag(:div,
      class: ["mensuration-sheet-doc__row", ("mensuration-sheet-doc__row--wide" if wide)].compact.join(" ")) do
      safe_join([
        content_tag(:dt, label),
        content_tag(:dd, value)
      ])
    end
  end

  def mensuration_measure_display(field, value)
    key = field["key"]
    if field["input"] == "choice"
      t("mensurations.choices.#{key}.#{value}", locale: :fr, default: value)
    else
      value
    end
  end

  # Groupes remplis, ordre métier stable.
  # exclude_on_svg: true → ne pas répéter les cm déjà sur Face/Profil ;
  # les mesures « dos » (épaules, ceinture) restent dans le panneau texte.
  MENSURATION_GROUP_ORDER = %w[silhouette longueurs vetements preferences].freeze
  MENSURATION_SVG_VIEWS = %w[face profil].freeze

  def mensuration_filled_field_groups(mensuration, exclude_clipped: false, exclude_on_svg: false)
    exclude_on_svg ||= exclude_clipped

    filled = mensuration.fields.select do |field|
      next false if mensuration.value_for(field["key"]).blank?

      if exclude_on_svg && field["clip"].present?
        view = MENSURATION_CLIP_VIEW[field["clip"]]
        next false if MENSURATION_SVG_VIEWS.include?(view)
      end

      true
    end
    grouped = filled.group_by { |field| field["group"].presence || "vetements" }
    MENSURATION_GROUP_ORDER.filter_map do |key|
      fields = grouped.delete(key)
      [key, fields] if fields.present?
    end + grouped.to_a
  end

  def mensuration_locale_switch_path(locale)
    if @invitation&.token
      mensuration_path(token: @invitation.token, locale: locale)
    else
      mensuration_gate_path(locale: locale)
    end
  end

  def mensuration_admin_meta_item(label, value)
    return if value.blank?

    content_tag(:div, class: "mensuration-admin-fiche__meta-item") do
      safe_join([
        content_tag(:dt, label),
        content_tag(:dd, value)
      ])
    end
  end

  # Payload JSON pour les silhouettes admin (clip + libellé court + valeur).
  def mensuration_silhouette_measures(mensuration)
    mensuration.fields.filter_map do |field|
      clip = field["clip"].presence
      next unless clip

      value = mensuration.value_for(field["key"])
      next if value.blank?

      key = field["key"]
      label = t("mensurations.fields.#{key}.name", locale: :fr, default: "").presence ||
              t("mensurations.fields.#{key}.short", locale: :fr).to_s.sub(/\s*\(cm\)\s*\z/i, "")
      { clip: clip, label: label, value: value }
    end
  end

  # Vues silhouette fiche admin : Face + Profil seulement (dos → panneau texte).
  MENSURATION_CLIP_VIEW = {
    "full" => "profil",
    "neck" => "face",
    "chest" => "face",
    "torso" => "face",
    "waist" => "face",
    "hips" => "face",
    "hips_pant" => "face",
    "thigh" => "face",
    "arm" => "profil",
    "leg_ext" => "profil",
    "leg_int" => "face",
    "shoulders" => "dos",
    "waist_belt" => "dos"
  }.freeze

  def mensuration_silhouette_panel_views(mensuration)
    by_view = Hash.new { |h, k| h[k] = 0 }
    mensuration_silhouette_measures(mensuration).each do |measure|
      view = MENSURATION_CLIP_VIEW[measure[:clip]]
      by_view[view] += 1 if MENSURATION_SVG_VIEWS.include?(view)
    end

    MENSURATION_SVG_VIEWS.select { |view| by_view[view].positive? }
  end

  private

  def stacked_control(id, label, field)
    content_tag(:div, class: "mensuration-field") do
      safe_join([
        (label_tag(id, mensuration_label_with_note(label), class: LABEL) if label.present? && id.present?),
        field
      ].compact)
    end
  end

  def mensuration_label_with_note(label)
    match = label.to_s.match(/\A(.+?)(\s*\(.+\))\z/)
    return label unless match

    safe_join([
      match[1],
      content_tag(:span, match[2], class: "mensuration-field__label-note")
    ])
  end

  def grouped_control(id, label, field, suffix: nil)
    content_tag(:div, class: "input-group input-group-sm mensuration-field--dock") do
      if suffix.present?
        safe_join([
          (label_tag(id, label, class: "visually-hidden") if label.present?),
          field,
          content_tag(:span, suffix, class: GROUP_LABEL, "aria-hidden": true)
        ].compact)
      else
        safe_join([label_tag(id, label, class: GROUP_LABEL), field])
      end
    end
  end
end
