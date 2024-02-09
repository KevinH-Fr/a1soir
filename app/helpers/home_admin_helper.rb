module HomeAdminHelper
  def dashboard_card(title, path, new_path, icon, items)
    content_tag(:div, class: "card m-2") do
      concat(content_tag(:div, class: "bg-dark text-light py-2") do
        concat(content_tag(:div, class: "row align-items-center m-0 p-0") do
          concat(content_tag(:div, class: "col text-start ") do
            concat(content_tag(:i, nil, class: "fa fa-xl brand-colored fa-#{icon} ms-1 me-1"))
          end)

          concat(content_tag(:div, class: "col text-center fw-bold") do
            concat(link_to title, path, class: "text-center no-underline")
          end)

          concat(content_tag(:div, class: "col text-end m-0 p-0") do
            concat(link_to("", new_path, class: "fa fa-add btn btn-warning btn-sm mx-2"))
          end)
        end)
      end)

      concat(content_tag(:div, class: "card-body body-bloc-dashboard") do
        concat(content_tag(:table, class: "table bloc-table table-primary table-striped table-hover m-0 p-0") do
          concat(content_tag(:tbody, class: "table-light table-dashboard") do
            items.each do |item|
              concat(content_tag(:tr) do
                concat(content_tag(:td) do
                  concat(content_tag(:i, nil, class: "fa fa-#{item[:icon]} me-1")) # Include icon for each item
                  concat(link_to item[:text], item[:path], class: "text-dark crop", style: "text-decoration: none;")
                end)
              end)
            end
          end)
        end)
      end)
    end
  end
end
