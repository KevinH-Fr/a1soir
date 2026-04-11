module AnalysesHelper
  def render_dashboard_section(title, icon_name = nil, partials)
    content_tag(:div, class: "card m-2 my-4 shadow-sm") do
      concat(content_tag(:div, class: "card-header bg-secondary text-light py-1") do
        concat(content_tag(:div, class: "d-flex align-items-center gap-2") do
          concat(content_tag(:i, "", class: "bi bi-#{icon_name}")) if icon_name.present?
          concat(content_tag(:span, title, class: "fw-bold"))
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

  # True when the current URL dates are not exactly one of the quick presets (custom range).
  def custom_period_filter_open?
    selected = [parse_date(params[:debut]), parse_date(params[:fin])]
    return false if selected.any?(&:nil?)

    quick_period_ranges.none? { |range| range == selected }
  end

  def date_range_filter_today_button(base_params:)
    selected_range = [parse_date(params[:debut]), parse_date(params[:fin])]
    label, range = quick_period_definitions.first
    debut, fin = range
    preset_button_link(label, debut, fin, selected_range, base_params)
  end

  def date_range_filter_range_presets_buttons(base_params:)
    selected_range = [parse_date(params[:debut]), parse_date(params[:fin])]
    safe_join(
      quick_period_definitions.drop(1).map do |label, range|
        debut, fin = range
        preset_button_link(label, debut, fin, selected_range, base_params)
      end,
      ""
    )
  end

  private

  def preset_button_link(label, debut, fin, selected_range, base_params)
    is_active = selected_range == [debut, fin]
    variant = is_active ? "primary" : "outline-secondary"
    link_to label,
            url_for(params: base_params.merge(debut: debut, fin: fin)),
            class: "btn btn-sm btn-#{variant}"
  end

  def quick_period_definitions
    today = Date.today
    prev_month = today.prev_month
    [
      ["Aujourd'hui", [today, today]],
      ["30 jours", [today - 29, today]],
      ["Mois courant", [today.beginning_of_month, today.end_of_month]],
      ["Mois précédent", [prev_month.beginning_of_month, prev_month.end_of_month]]
    ]
  end

  def quick_period_ranges
    quick_period_definitions.map(&:last)
  end

  def parse_date(value)
    Date.parse(value.to_s) rescue nil
  end
end
  