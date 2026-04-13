module ShowModelHelper
  # totals_inline : fragment HTML (partial avec id pour Turbo), sur la même ligne que le titre, à droite avant le bouton d’action.
  def card_main_model(title, icon, first_link_content = nil, totals_inline: nil)
    content_tag(:div, class: "card mx-1 mx-md-2 p-0 shadow-sm my-1 card-main-model-section") do
      concat(content_tag(:div, class: "card-header rounded bg-dark text-light py-1 py-md-2 px-2 px-md-3 d-flex align-items-center") do
        concat(content_tag(:div, class: "card-main-model-header-row d-flex flex-nowrap flex-md-wrap align-items-center gap-1 gap-md-2 w-100 min-w-0") do
          concat(content_tag(:div, class: "d-flex align-items-center min-w-0 flex-shrink-1") do
            concat(content_tag(:i, nil, class: "bi bi-xl brand-colored bi-#{icon} ms-0 me-1 me-md-3 flex-shrink-0 card-main-model-header-icon"))
            concat(content_tag(:div, title, class: "fw-bold text-light text-truncate min-w-0 fs-6 card-main-model-title"))
          end)
          concat(content_tag(:div, class: "d-flex flex-nowrap align-items-center gap-1 gap-md-2 justify-content-end ms-auto flex-shrink-0 card-main-model-header-actions") do
            concat(totals_inline) if totals_inline.present?
            concat(first_link_content) if first_link_content.present?
          end)
        end)
      end)
    end
  end
end
