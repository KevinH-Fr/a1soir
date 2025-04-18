module ShowModelHelper
  def card_main_model(title, icon, first_link_content = nil)
    content_tag(:div, class: "card mx-2 p-0 shadow-sm my-1") do
      concat(content_tag(:div, class: "card-header rounded bg-dark text-light d-flex justify-content-between align-items-center py-2") do
        concat(content_tag(:div, class: "d-flex align-items-center") do
          concat(content_tag(:i, nil, class: "bi bi-xl brand-colored bi-#{icon} ms-1 me-3"))
          concat(content_tag(:div, title, class: "fw-bold text-light fs-6"))
        end)
        concat(content_tag(:div, class: "mx-1") do
          concat(first_link_content) if first_link_content
        end)
      end)
    end
  end
end
