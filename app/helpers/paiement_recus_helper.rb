module PaiementRecusHelper

    def badges_paiements_synthese(paiements)
      prix = paiements.only_prix.sum(:montant).to_d
      caution = paiements.only_caution.sum(:montant).to_d

      chips = []
      chips << synthese_kpi_chip("Prix", custom_currency_format(prix), icon: "currency-euro") unless prix.zero?
      chips << synthese_kpi_chip("Caution", custom_currency_no_decimals_format(caution), icon: "shield-lock") unless caution.zero?

      admin_synthese_kpi_strip do
        safe_join(chips)
      end
    end

    # Totaux Stripe (e-shop) : même structure DOM que `badges_paiements_synthese`.
    def badges_stripe_paiement_synthese(commande)
      stripe_payment = commande.stripe_payment
      return "".html_safe unless stripe_payment.present?

      total = stripe_payment.amount.to_d / 100
      chips = []
      chips << synthese_kpi_chip("Prix", custom_currency_format(total), icon: "currency-euro") unless total.zero?

      admin_synthese_kpi_strip do
        safe_join(chips)
      end
    end
end
