module FormDesignHelper
  # add a label 
  # verify other form are not broken

  def custom_form_elements(form, *fields)
    content_tag(:div, class: "p-1") do
      fields.each do |field_data|
        field, field_type, label = field_data
        label = label.is_a?(String) ? label : nil  # Use the third argument as label text if it's a string
  
        concat(content_tag(:div, class: "form-group input-group mb-1") do
          if field_type != :check_box && label
            concat(content_tag(:div, class: "input-group-text") do
              concat(form.label(field, label, class: "form-label"))  # Use provided label if present
            end)
          elsif field_type != :check_box
            concat(content_tag(:div, class: "input-group-text") do
              concat(form.label(field, class: "form-label"))  # Default behavior if no label passed
            end)
          end
  
          field_options = { class: "form-control" }
  
          if field_type == :text_field || field_type == :text_area
            concat(form.public_send(field_type, field, field_options))
          elsif field_type == :number_field
            concat(form.public_send(field_type, field, field_options.merge(type: "number")))
          elsif field_type == :date_field
            concat(form.public_send(field_type, field, field_options.merge(type: "date")))
          elsif field_type == :check_box
            concat(content_tag(:div, class: "form-check form-switch text-start fs-5 my-2 d-flex align-items-center") do
              concat(form.check_box(field, class: "form-check-input me-2"))
              concat(form.label(field, form.object.class.human_attribute_name(field), class: "form-check-label fs-6"))
            end)
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
        concat content_tag(:i, "", class: "bi-check-circle")
      end
    end
  end

end
  