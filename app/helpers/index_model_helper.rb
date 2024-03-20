module IndexModelHelper

  def bandeau_entete_simple(title, icon)
    content_tag(:div, class: "card m-2 shadow-sm") do
      concat(content_tag(:div, class: "card-header bg-dark text-light d-flex justify-content-between align-items-center py-2") do
        concat(content_tag(:div, class: "d-flex align-items-center") do
          concat(content_tag(:i, nil, class: "fa fa-xl brand-colored fa-#{icon} ms-1 me-3"))
          concat(content_tag(:div, title, class: "fw-bold text-light fs-5"))
        end)
      end)
    end
  end

  def bandeau_entete(title, icon, counter, champs_recherche)
    content_tag(:div, class: "card m-2 shadow-sm") do
      concat(content_tag(:div, class: "card-header bg-dark text-light d-flex justify-content-between align-items-center py-2") do
        concat(content_tag(:div, class: "d-flex align-items-center") do
          concat(content_tag(:i, nil, class: "fa fa-xl brand-colored fa-#{icon} ms-1 me-3"))
          concat(content_tag(:div, title, class: "fw-bold text-light fs-5"))
        end)

        concat(content_tag(:span, counter, class: "badge rounded-pill bg-primary fs-5"))
      end)

      if champs_recherche.present?
        concat(content_tag(:div, class: "card-body p-1 light-beige-colored") do
          concat(content_tag(:div, class: "d-flex align-items-center") do

            concat(index_search_form(@q, champs_recherche )) # Call the client_search_form helper method
        
            # New button with collapse attributes
            concat(content_tag(:button, class: "btn btn-sm btn-warning", type: "button", 
                data: { bs_toggle: "collapse", bs_target: "#collapseNew", aria_expanded: "false" },
                aria: { controls: "collapseNew" }) do
                concat(content_tag(:i, nil, class: "fa-solid fa-square-plus fa-xl"))
            end)

          end)
            
        end)    
      end

    end

  end

  def index_search_form(q, champs_recherche)
    search_form_for q, html: { class: "d-flex align-items-center w-100" } do |f|
      concat(f.search_field champs_recherche, class: "form-control flex-grow-1 mx-1", type: "text", placeholder: "Chercher...")
      concat(button_tag(type: "submit", class: "btn btn-sm btn-success fw-bold me-1") do
        concat(content_tag(:i, "", class: "fa-solid fa-xl fa-magnifying-glass"))
      end)
    end
  end


  def bloc_nouveau(model_class)

      content_tag(:div, class: "collapse", id: "collapseNew") do
          concat(content_tag(:div, id: "new") do
              render partial: "#{model_class.to_s.underscore.pluralize}/form", 
              locals: { model_class.to_s.underscore.to_sym => model_class.new }
          end)
      end
  end


  def links_record(model)
      content_tag(:div, class: "d-flex justify-content-end") do
          concat(link_to("", model, class: "btn btn-sm btn-primary fa-solid fa-eye m-1 p-2"))
          concat(button_to("", edit_polymorphic_path(model), method: :post, class: "btn btn-sm btn-secondary fa-solid fa-pen-to-square m-1 p-2"))
          concat(button_to("", model, method: :delete, data: { confirm: 'Are you sure?' }, class: "btn btn-sm btn-danger fa-solid fa-trash m-1 p-2"))
      end
  end 

  def return_model_index_button(text, path)
    content_tag(:div, class: "m-1 d-flex align-items-center") do
      link_to path, class: "btn bg-dark text-light fw-bold d-flex align-items-center" do
          content_tag(:i, "", class: "fa-solid fa-xl fa-arrow-left") +
          content_tag(:span, text, class: "ms-2")
      end
    end
  end

end
  