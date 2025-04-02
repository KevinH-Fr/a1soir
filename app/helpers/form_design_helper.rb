module FormDesignHelper
  # add a label 
  # verify other form are not broken

  def custom_form_elements(form, *fields)
    content_tag(:div, class: "p-1") do
      fields.each do |field_data|
        field, field_type, label, options = field_data
        label = label.is_a?(String) ? label : nil
        options ||= {}
  
        concat(content_tag(:div, class: "form-group input-group mb-1") do
          # Label rendering (skip for check_box)
          if field_type != :check_box
            concat(content_tag(:div, class: "input-group-text") do
              concat(form.label(field, label || form.object.class.human_attribute_name(field), class: ""))
            end)
          end
  
          # Field rendering
          case field_type
          when :text_field, :text_area
            concat(form.public_send(field_type, field, { class: "form-control" }.merge(options)))
          when :number_field
            concat(form.number_field(field, { class: "form-control", step: "any" }.merge(options)))
          when :date_field
            concat(form.date_field(field, { class: "form-control" }.merge(options)))
          when :collection_select
            collection = options.delete(:collection)
            value_method = options.delete(:value_method)
            label_method = options.delete(:label_method)
            select_options = options.delete(:select_options) || {}
            concat(form.collection_select(field, collection, value_method, label_method, select_options, { class: "form-select" }.merge(options)))
          when :check_box
            concat(content_tag(:div, class: "form-check form-switch text-start fs-6 my-1 d-flex align-items-center") do
              concat(form.check_box(field, class: "form-check-input me-2"))
              concat(form.label(field, form.object.class.human_attribute_name(field), class: "form-check-label"))
            end)
          when :file_field
            concat(form.file_field(field, { class: "form-control" }.merge(options)))          
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
  