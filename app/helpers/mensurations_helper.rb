# Champ + petit libellé au-dessus (toujours visible une fois saisi).
module MensurationsHelper
  CONTROL = "form-control form-control-sm bg-dark text-light border-secondary"
  SELECT = "form-select form-select-sm bg-dark text-light border-secondary"
  LABEL = "form-label small text-light opacity-75 mb-1"

  def mensuration_labeled_field(name, value, label, type: :text, **opts)
    id = opts.delete(:id).presence || (name.present? ? sanitize_to_id(name) : nil)
    classes = [CONTROL, opts.delete(:class)].compact.join(" ")
    field_opts = opts.merge(id: id, class: classes)

    field = case type
            when :tel then telephone_field_tag(name, value, field_opts)
            when :date then date_field_tag(name, value, field_opts)
            when :textarea then text_area_tag(name, value, field_opts.merge(rows: opts[:rows] || 2))
            else text_field_tag(name, value, field_opts)
            end

    safe_join([label_tag(id, label, class: LABEL), field])
  end

  def mensuration_labeled_select(name, option_tags, label, **opts)
    id = opts.delete(:id).presence || sanitize_to_id(name)
    classes = [SELECT, opts.delete(:class)].compact.join(" ")

    safe_join([
      label_tag(id, label, class: LABEL),
      select_tag(name, option_tags, opts.merge(id: id, class: classes))
    ])
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

  def mensuration_admin_meta_item(label, value)
    return if value.blank?

    content_tag(:div, class: "mensuration-admin-fiche__meta-item") do
      safe_join([
        content_tag(:dt, label),
        content_tag(:dd, value)
      ])
    end
  end
end
