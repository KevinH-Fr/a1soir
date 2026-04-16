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
        concat(content_tag(:table, class: "table table-sm table-primary table-striped table-hover m-0 p-0", style: "table-layout: fixed;") do
          concat(content_tag(:tbody, class: "table-light") do
            items.each do |item|
              concat(content_tag(:tr) do
                concat(content_tag(:td, class: "text-truncate align-middle") do
                  if item[:order_ref].present?
                    concat(link_to(item[:path], class: "text-dark text-decoration-none") do
                      concat item[:order_ref]
                      concat item[:tail].to_s
                      if item[:row_icon] == :eshop
                        concat content_tag(:i, nil,
                          class: "bi bi-cart-check text-warning ms-2",
                          title: "Commande e-shop")
                      end
                    end)
                  else
                    case item[:row_icon]
                    when :eshop
                      concat(content_tag(:i, nil,
                        class: "bi bi-cart-check text-warning me-1",
                        title: "Commande e-shop"))
                    when :none, false
                      # pas d’icône
                    else
                      concat(content_tag(:i, nil))
                    end
                    concat(link_to(item[:text], item[:path], class: "text-dark text-decoration-none"))
                  end
                end)
              end)
            end
          end)
        end)
      end)
    end
  end

  def options_supplementaires_link(path, icon_class, text, btn_class, badge_count: nil, badge_show_zero: false, badge_class: "bg-danger")
    classes = [
      "admin-quick-action-btn",
      "btn btn-sm rounded-3 px-2 d-inline-flex align-items-center justify-content-center gap-2",
      "me-1 mb-2 position-relative text-nowrap",
      btn_class
    ]
    link_to(path, class: classes.join(" ")) do
      concat content_tag(:i, "", class: "bi #{icon_class} flex-shrink-0")
      concat content_tag(:span, text, class: "")
      if !badge_count.nil? && (badge_show_zero || badge_count > 0)
        concat content_tag(:span, badge_count,
          class: "position-absolute top-0 start-100 translate-middle badge rounded-pill #{badge_class}",
          style: "font-size: 0.65rem; padding: 0.2rem 0.4rem;")
      end
    end
  end


end
