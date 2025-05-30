module HomeAdminHelper
  def dashboard_card(title, path, new_path, icon, items)
    content_tag(:div, class: "card m-2 shadow-sm") do
      concat(content_tag(:div, class: "card-header bg-dark text-light p-1 px-2") do
        concat(content_tag(:div, class: "row align-items-center m-0 p-0") do
          concat(content_tag(:div, class: "col text-start m-0 p-0") do
            concat(content_tag(:i, nil, class: "bi brand-colored bi-#{icon} fs-3"))
          end)

          concat(content_tag(:div, class: "col text-center fw-bold text-nowrap") do
            concat(link_to title, path, class: "text-center text-decoration-none text-light fs-6")
          end)

          concat(content_tag(:div, class: "col text-end m-0 p-0") do
            concat(link_to("", new_path, class: "bi bi-plus-lg btn btn-warning btn-sm"))
          end)
        end)
      end)

      concat(content_tag(:div, class: "card-body p-0 light-beige-colored") do
        concat(content_tag(:table, class: "table table-primary table-striped table-hover m-0 p-0") do
          concat(content_tag(:tbody, class: "table-light") do
            items.each do |item|
              concat(content_tag(:tr) do
                concat(content_tag(:td) do
                  concat(content_tag(:i, nil, class: "bi bi-#{item[:icon]} me-1")) # Include icon for each item
                  concat(link_to item[:text], item[:path], class: "text-dark crop text-decoration-none")
                end)
              end)
            end
          end)
        end)
      end)
    end
  end

  def options_supplementaires_link(path, icon_class, text, btn_class)
    link_to(path, class: "me-1 mb-2 btn btn-sm #{btn_class}") do
      concat content_tag(:i, "", class: "bi #{icon_class} me-1")
      concat content_tag(:span, text, class: "fw-bold")
    end
  end


end
