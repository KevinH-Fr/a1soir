module PaiementRecusHelper

    def badges_paiements_synthese(paiements)
        content_tag(:div, class: "container-fluid text-center") do
          concat(content_tag(:span, class: "badge fs-6 bg-secondary mx-1") do
            concat("Paiements: ")
            concat(content_tag(:span, paiements.count, class: ""))
          end)
    
          concat(content_tag(:span, class: "badge fs-6 bg-secondary mx-1") do
            concat("Prix: ")
            concat(content_tag(:span, custom_currency_format(paiements.only_prix.sum(:montant)), class: ""))
          end)
  
          concat(content_tag(:span, class: "badge fs-6 bg-secondary mx-1") do
            concat("Caution: ")
            concat(content_tag(:span, custom_currency_no_decimals_format(paiements.only_caution.sum(:montant)), class: ""))
          end)

        end
      end

    # Totaux Stripe (e-shop) : même structure DOM que `badges_paiements_synthese`.
    def badges_stripe_paiement_synthese(commande)
      stripe_payment = commande.stripe_payment
      return "".html_safe unless stripe_payment.present?

      nb_paiements = commande.paiement_recus.count + 1
      total = stripe_payment.amount.to_f / 100

      content_tag(:div, class: "container-fluid text-center") do
        concat(content_tag(:span, class: "badge fs-6 bg-secondary mx-1") do
          concat("Paiements: ")
          concat(content_tag(:span, nb_paiements, class: ""))
        end)

        concat(content_tag(:span, class: "badge fs-6 bg-secondary mx-1") do
          concat("Prix: ")
          concat(content_tag(:span, custom_currency_format(total), class: ""))
        end)

        concat(content_tag(:span, class: "badge fs-6 bg-secondary mx-1") do
          concat("Caution: ")
          concat(content_tag(:span, custom_currency_no_decimals_format(0), class: ""))
        end)
      end
    end
end
