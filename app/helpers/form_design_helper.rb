module FormDesignHelper

  def custom_form_elements(form, *fields)
    content_tag(:div, class: "m-1 p-2") do
      fields.each do |field, field_type, options|
        concat(content_tag(:div, class: "form-group input-group mb-1") do
          concat(content_tag(:div, class: "input-group-text") do
            concat(form.label field)
          end)
  
          field_options = { class: "form-control" }
  
          if field_type == :text_field || field_type == :text_area
            concat(form.public_send(field_type, field, field_options))
          elsif field_type == :number_field
            concat(form.public_send(field_type, field, field_options.merge(type: "number")))
          elsif field_type == :date_field
            concat(form.public_send(field_type, field, field_options.merge(type: "date")))
          else
            # Handle other field types as needed
          end
        end)
      end
    end
  end
  
  

  def custom_submit_button(form)
    content_tag(:div, class: "container-fluid p-2 p-0 text-end") do
      button_tag(type: "submit", class: "btn w-25 bg-success text-light fw-bold") do
        concat content_tag(:i, "", class: "fa-solid fa-xl fa-check-circle")
      end
    end
  end

end
  