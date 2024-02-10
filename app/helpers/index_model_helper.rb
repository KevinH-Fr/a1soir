module IndexModelHelper
    def bandeau_entete(title, icon, counter, search)
      content_tag(:div, class: "card m-2 shadow-sm") do
        concat(content_tag(:div, class: "card-header bg-dark text-light d-flex justify-content-between align-items-center py-2") do
          concat(content_tag(:div, class: "d-flex align-items-center") do
            concat(content_tag(:i, nil, class: "fa fa-xl brand-colored fa-#{icon} ms-1 me-3"))
            concat(content_tag(:div, title, class: "fw-bold text-light fs-5"))
          end)
  
          concat(content_tag(:span, counter, class: "badge rounded-pill bg-primary fs-5"))
        end)
        concat(content_tag(:div, class: "card-body p-0 light-beige-colored") do
            concat(content_tag(:div, class: "d-flex align-items-center") do

                concat(content_tag(:input, nil, class: "form-control", type: "text", placeholder: "Search"))
                concat(content_tag(:button, "Search", class: "btn btn-outline-dark p-1 m-1", type: "button"))

                # New button with collapse attributes
                concat(content_tag(:button, class: "btn btn-sm btn-warning m-2", type: "button", 
                    data: { bs_toggle: "collapse", bs_target: "#collapseNew", aria_expanded: "false" },
                    aria: { controls: "collapseNew" }) do
                    concat(content_tag(:i, nil, class: "fa-solid fa-square-plus fa-xl"))
                end)

            end)
 
        end)
   
      end

    end


    def bloc_nouveau(model_class)
        content_tag(:div, class: "card m-2 shadow-sm") do
            concat(content_tag(:div, class: "card-body p-0 light-beige-colored") do

                content_tag(:div, class: "collapse", id: "collapseNew") do
                    concat(content_tag(:div, id: "new") do
                        render partial: "#{model_class.to_s.underscore.pluralize}/form", locals: { model_class.to_s.underscore.to_sym => model_class.new }
                    end)
                end
            end)
        end
    end


    def model_collection(collection, model_name)
        content_tag(:div, id: "#{model_name.to_s.underscore.pluralize}") do
            collection.each do |model|
                concat(content_tag(:div, class: "card m-2 shadow-sm") do
                    concat(content_tag(:div, class: "card-body p-2 light-beige-colored") do
                        concat(render(model))
                        concat(content_tag(:div, class: "d-flex justify-content-end") do
                            concat(link_to("Show", model, class: "btn btn-primary m-1"))
                            concat(link_to("Edit", edit_polymorphic_path(model), class: "btn btn-secondary m-1"))
                            concat(button_to("Destroy", model, method: :delete, data: { confirm: 'Are you sure?' }, class: "btn btn-danger m-1"))
                        end)

                    end)
                end)
            end
        end
    end
      

  end
  