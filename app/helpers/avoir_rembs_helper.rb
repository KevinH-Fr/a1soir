module AvoirRembsHelper

    def badges_avoirrembs_synthese(commande)
        content_tag(:div, class: "container-fluid text-center") do
          concat(content_tag(:span, class: "badge fs-6 bg-secondary mx-1") do
            concat("Avoir: ")
            concat(content_tag(:span, custom_currency_no_decimals_format(avoir_deduit(commande)), class: ""))
          end)
    
          concat(content_tag(:span, class: "badge fs-6 bg-secondary mx-1") do
            concat("Remboursement: ")
            concat(content_tag(:span, custom_currency_no_decimals_format(remb_deduit(commande)), class: ""))
          end)
  
  
        end
      end
end
