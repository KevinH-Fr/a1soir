module IndexModelHelper

  def bandeau_entete_simple(title, icon)
    content_tag(:div, class: "card m-2 shadow-sm") do
      concat(content_tag(:div, class: "card-header bg-dark text-light d-flex justify-content-between align-items-center py-2") do
        concat(content_tag(:div, class: "d-flex align-items-center") do
          concat(content_tag(:i, nil, class: "bi bi-xl brand-colored bi-#{icon} ms-1 me-3"))
          concat(content_tag(:div, title, class: "fw-bold text-light fs-5"))
        end)
      end)
    end
  end

  def bandeau_entete(title, icon, counter, champs_recherche, search_path)
    content_tag(:div, class: "card m-2 shadow-sm") do
      concat(content_tag(:div, class: "card-header bg-dark text-light d-flex justify-content-between align-items-center py-2") do
        concat(content_tag(:div, class: "d-flex align-items-center") do
          concat(content_tag(:i, nil, class: "bi bi-xl brand-colored bi-#{icon} ms-1 me-3"))
          concat(content_tag(:div, title, class: "fw-bold text-light fs-5"))
        end)

        concat(content_tag(:span, counter, class: "badge rounded-pill bg-primary fs-5"))
      end)

      if champs_recherche.present?
        concat(content_tag(:div, class: "card-body p-1 light-beige-colored") do
          concat(content_tag(:div, class: "d-flex align-items-center") do

          #  concat(index_search_form(@q, champs_recherche )) # Call the client_search_form helper method
        
           concat(index_search_form(@q, search_path, champs_recherche)) # Call the client_search_form helper method

            # New button with collapse attributes
            concat(content_tag(:button, class: "btn btn-sm btn-warning", type: "button", 
                data: { bs_toggle: "collapse", bs_target: "#collapseNew", aria_expanded: "false" },
                aria: { controls: "collapseNew" }) do
                concat(content_tag(:i, nil, class: "bi bi-plus-lg fa-xl"))
            end)

          end)
            
        end)    
      end

    end

  end
  
  def index_search_form(q, chemin_recherche, champs_recherche)
    render partial: 'admin/shared/search_form', locals: {chemin_recherche: chemin_recherche, champs_recherche: champs_recherche }
  end

  def bloc_nouveau(model_class)

      content_tag(:div, class: "collapse", id: "collapseNew") do
          concat(content_tag(:div, id: "new") do
              render partial: "admin/#{model_class.to_s.underscore.pluralize}/form", 
              locals: { model_class.to_s.underscore.to_sym => model_class.new }
          end)
      end
  end

  def links_record(model, turbo_delete: true)
    content_tag(:div, class: "d-flex justify-content-end gap-1") do
      concat(link_to("", [:admin, model], class: "btn btn-sm btn-primary bi bi-arrow-up-right-square", data: { turbo: false }))
      concat(button_to("", edit_polymorphic_path([:admin, model]), method: :post, class: "btn btn-sm btn-secondary bi bi-pencil-square"))
      concat(button_to("", [:admin, model], method: :delete, data: { turbo: turbo_delete }, 
        onclick: "return confirm('Êtes-vous certain de vouloir supprimer cet élément et tous les éléments liés ?')",
        class: "btn btn-sm btn-danger bi bi-trash"))
    end
  end
  

  def return_model_index_button(text, path)
    content_tag(:div, class: "m-1 d-flex align-items-center") do
      link_to path, class: "btn bg-dark text-light fw-bold d-flex align-items-center" do
          content_tag(:i, "", class: "bi bi-arrow-return-left") +
          content_tag(:span, text, class: "ms-2")
      end
    end
  end

end
  