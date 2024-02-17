module ShowModelHelper
  def card_main_model(title, icon, collapse_link_content = nil)
    content_tag(:div, class: "card mx-2 p-0 shadow-sm my-1") do
      concat(content_tag(:div, class: "card-header rounded bg-dark text-light d-flex justify-content-between align-items-center py-2") do
        concat(content_tag(:div, class: "d-flex align-items-center") do
          concat(content_tag(:i, nil, class: "fa fa-xl brand-colored fa-#{icon} ms-1 me-3"))
          concat(content_tag(:div, title, class: "fw-bold text-light fs-5"))
        end)
        concat(collapse_link_content) if collapse_link_content
      end)
    end
  end

end
  