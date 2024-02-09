module HomeAdminHelper
  def dashboard_card(title, path, items, icon)
    content_tag(:div, class: "card m-2") do
      concat(content_tag(:div, class: "header-bloc-dashboard d-flex justify-content-between align-items-center p-2") do
        concat(content_tag(:div, class: "format-titre-dashboard text-start") do
          concat(content_tag(:i, nil, class: "fa iconcolor fa-#{icon} ms-1 me-1"))
          concat(link_to title, path, class: "format-titre-dashboard text-start text-dark", style: "text-decoration: none;")
        end)

        concat(content_tag(:div, class: "text-end") do
          concat(link_to("", new_client_path, class: "fa fa-add add-dashboard btn btn-sm"))
        end)
      end)

      concat(content_tag(:div, class: "card-body body-bloc-dashboard p-2") do
        concat(content_tag(:div, class: "row") do
          items.each do |item|
            concat(content_tag(:div, class: "col-12 col-md-6") do
              concat(content_tag(:div, class: "d-flex align-items-center") do
                concat(content_tag(:i, nil, class: "fa fa-#{item[:icon]} me-1"))
                concat(link_to item[:text], item[:path], class: "text-dark crop", style: "text-decoration: none;")
              end)
            end)
          end
        end)
      end)
    end
  end
end
