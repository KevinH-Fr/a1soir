# Champ + libellé : stack moderne par défaut ; group réservé au dock SVG (suffixe cm).
module MensurationsHelper
  CONTROL = "form-control bg-dark text-light border-secondary mensuration-field__control"
  GROUP_CONTROL = "form-control form-control-sm border-secondary mensuration-guide__value"
  SELECT = "form-select bg-dark text-light border-secondary mensuration-field__control"
  GROUP_SELECT = "form-select form-select-sm text-light border-secondary"
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

  def mensuration_labeled_field(name, value, label, type: :text, layout: :stack, **opts)
    id = opts.delete(:id).presence || (name.present? ? sanitize_to_id(name) : nil)
    addon = opts.delete(:addon)
    classes = [(layout == :group ? GROUP_CONTROL : CONTROL), opts.delete(:class)].compact.join(" ")
    field_opts = opts.merge(id: id, class: classes)
    field_opts[:data] = (field_opts[:data] || {}).merge(initial_value: value) if value.present?

    field = case type
            when :tel then telephone_field_tag(name, value, field_opts)
            when :date then date_field_tag(name, value, field_opts)
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

  # Pastille admin : libellé court + valeur mise en avant.
  def mensuration_measure_chip(field, value)
    key = field["key"]
    display = if field["input"] == "choice"
                t("mensurations.choices.#{key}.#{value}", locale: :fr, default: value)
              else
                value
              end
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

  private

  def stacked_control(id, label, field)
    content_tag(:div, class: "mensuration-field") do
      safe_join([
        (label_tag(id, label, class: LABEL) if label.present? && id.present?),
        field
      ].compact)
    end
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
