module AnalysesHelper
    def render_dashboard_section(title, partials)
      content_tag(:div, class: "card m-2 shadow-sm") do
        concat(content_tag(:div, class: "card-header bg-secondary text-light py-2") do
          concat(content_tag(:div, class: "row align-items-center m-0 p-1") do
            concat(content_tag(:div, class: "col text-center fw-bold m-0 p-0") do
              concat(title)
            end)
          end)
        end)
    
        concat(content_tag(:div, class: "card-body p-0 light-beige-colored") do
          concat(content_tag(:div, class: "row p-2") do
            partials.each do |partial|
              concat(content_tag(:div, class: "col-sm-4 my-2") do
                render partial
              end)
            end
          end)
        end)
      end
    end

    def date_range_filter_buttons(base_params:)
      today = Date.today
      selected_range = [
        parse_date(params[:debut]),
        parse_date(params[:fin])
      ]
  
      buttons = [
        { label: "Aujourd'hui", range: [today, today] },
        { label: "30 jours", range: [today - 29, today] },
        { label: "Mois courant", range: [today.beginning_of_month, today.end_of_month] }
      ]
  
      safe_join(buttons.map do |btn|
        debut, fin = btn[:range]
        is_active = selected_range == [debut, fin]
        css_class = is_active ? "btn-primary" : "btn-outline-primary"
  
        link_to btn[:label],
                url_for(params: base_params.merge(debut: debut, fin: fin)),
                class: "btn btn-sm #{css_class} rounded"
      end, " ")
    end
  
    private
  
    def parse_date(value)
      Date.parse(value.to_s) rescue nil
    end
end
  