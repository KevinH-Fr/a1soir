module ShowModelHelper
    def card_main_model(title, icon)
        content_tag(:div, class: "card mx-2 p-0 shadow-sm") do
            concat(content_tag(:div, class: "card-header bg-dark text-light d-flex justify-content-between align-items-center py-2") do
                concat(content_tag(:div, class: "d-flex align-items-center") do
                concat(content_tag(:i, nil, class: "fa fa-xl brand-colored fa-#{icon} ms-1 me-3"))
                concat(content_tag(:div, title, class: "fw-bold text-light fs-5"))
                end)
            end)

        end
    end
end



