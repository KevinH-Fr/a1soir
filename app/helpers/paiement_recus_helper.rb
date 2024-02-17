module PaiementRecusHelper

    def badges_paiements_synthese(paiements)
        content_tag(:div, class: "container-fluid text-center") do
          concat(content_tag(:span, class: "badge fs-5 bg-secondary mx-1") do
            concat("Paiements: ")
            concat(content_tag(:span, paiements.count, class: ""))
          end)
    
          concat(content_tag(:span, class: "badge fs-5 bg-secondary mx-1") do
            concat("Prix: ")
            concat(content_tag(:span, custom_currency_format(paiements.only_prix.sum(:montant)), class: ""))
          end)
  
          concat(content_tag(:span, class: "badge fs-5 bg-secondary mx-1") do
            concat("Caution: ")
            concat(content_tag(:span, custom_currency_format(paiements.only_caution.sum(:montant)), class: ""))
          end)

        end
      end
end
