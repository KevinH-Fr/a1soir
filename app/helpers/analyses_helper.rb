module AnalysesHelper
    def render_dashboard_section(title, partials)
      content_tag(:div, class: "card m-2 shadow-sm") do
        concat(content_tag(:div, class: "card-header bg-dark text-light py-2") do
          concat(content_tag(:div, class: "row align-items-center m-0 p-1") do
            concat(content_tag(:div, class: "col text-center fw-bold m-0 p-0") do
              concat(title)
            end)
          end)
        end)
    
        concat(content_tag(:div, class: "card-body p-0 light-beige-colored") do
          concat(content_tag(:div, class: "row") do
            partials.each do |partial|
              concat(content_tag(:div, class: "col-md-4") do
                render partial
              end)
            end
          end)
        end)
      end
    end
  end
  