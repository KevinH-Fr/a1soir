
module HomeAdminHelper
    def dashboard_card(title, path, items)
      content_tag(:div, class: "card bloc-dashboard") do
        concat(content_tag(:div, class: "header-bloc-dashboard") do
          concat(content_tag(:div, class: "row align-items-center m-0 p-0") do
            concat(content_tag(:div, class: "col format-titre-dashboard text-start") do
              concat(content_tag(:i, nil, class: "fa iconcolor fa-user ms-1 me-1"))
            end)
  
            concat(content_tag(:div, class: "col format-titre-dashboard text-center") do
              concat(link_to title, path, class: "format-titre-dashboard text-center")
            end)
  
            concat(content_tag(:div, class: "col text-end m-0 p-0") do
              concat(link_to "", new_client_path, class: "fa fa-add add-dashboard btn btn-sm")
            end)
          end)
        end)
  
        concat(content_tag(:div, class: "card-body body-bloc-dashboard") do
          concat(content_tag(:table, class: "table bloc-table table-primary table-striped table-hover m-0 p-0") do
            concat(content_tag(:tbody, class: "table-light table-dashboard") do
              items.each do |item|
                concat(content_tag(:tr) do
                  concat(content_tag(:td) do
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
  