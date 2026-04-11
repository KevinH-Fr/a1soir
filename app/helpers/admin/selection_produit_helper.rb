# frozen_string_literal: true

module Admin::SelectionProduitHelper
  def selection_hidden_categorie_produit_ids(categorie_ids)
    safe_join(Array(categorie_ids).map { |id| hidden_field_tag("categorie_produit[]", id) })
  end

  def selection_hidden_taille_ids(taille_ids)
    safe_join(Array(taille_ids).map { |id| hidden_field_tag("taille[]", id) })
  end

  # Carte d’étape. compact: true = une ligne : icône + titre + contenu (ex. select).
  def selection_filter_section(title:, icon: nil, heading_id:, body_class: nil, compact: false, &block)
    default_chips = "d-flex flex-wrap justify-content-center align-items-center gap-2"
    section_class = if compact
                      "rounded-2 border border-secondary-subtle bg-body-tertiary px-2 py-2 mb-2"
                    else
                      "rounded-3 border border-secondary-subtle bg-body-tertiary p-3 mb-3"
                    end

    if compact
      icon_box = "d-inline-flex align-items-center justify-content-center rounded-1 bg-primary bg-opacity-10 text-primary px-1 py-0 flex-shrink-0"
      row = content_tag(:div, class: "d-flex flex-wrap align-items-center gap-2 w-100") do
        bits = []
        if icon.present?
          bits << content_tag(:span, class: icon_box, aria: { hidden: true }) do
            content_tag(:i, "", class: "bi #{icon} fs-6", aria: { hidden: true })
          end
        end
        bits << content_tag(:h2, title, id: heading_id, class: "small mb-0 fw-semibold text-body text-nowrap flex-shrink-0")
        bits << content_tag(:div, class: "flex-grow-1 min-w-0") { capture(&block) }
        safe_join(bits)
      end
      return content_tag(:section, class: section_class, aria: { labelledby: heading_id }) { row }
    end

    header = content_tag(:div, class: "d-flex align-items-center justify-content-center gap-2 mb-3 pb-2") do
      parts = []
      if icon.present?
        parts << content_tag(:span, class: "d-inline-flex align-items-center justify-content-center rounded-2 bg-primary bg-opacity-10 text-primary p-2", aria: { hidden: true }) do
          content_tag(:i, "", class: "bi #{icon}", aria: { hidden: true })
        end
      end
      parts << content_tag(:h2, title, id: heading_id, class: "h6 mb-0 fw-semibold text-body")
      safe_join(parts)
    end
    body = content_tag(:div, class: body_class || default_chips, &block)
    content_tag(:section, class: section_class, aria: { labelledby: heading_id }) do
      safe_join([header, body])
    end
  end
end
