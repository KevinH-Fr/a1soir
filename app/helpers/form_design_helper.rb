module FormDesignHelper
    def custom_form_elements(form, *fields)
        content_tag(:div, class: "p-2") do
          fields.each do |field, field_type|
            concat(content_tag(:div, class: "form-group input-group mb-2") do
              concat(content_tag(:div, class: "input-group-text") do
                concat(form.label field)
              end)
              
              concat(form.public_send(field_type, field, class: "form-control"))
            end)
          end
    
          # Submit button
          concat(content_tag(:div, class: "m-2 d-flex justify-content-end") do
            concat(form.submit(class: "btn btn-primary"))
          end)
        end
    end
end
  