module AvoirRembsHelper

    def badges_avoirrembs_synthese(commande)
      av = avoir_deduit(commande).to_d
      remb = remb_deduit(commande).to_d

      chips = []
      chips << synthese_kpi_chip("Avoir", custom_currency_no_decimals_format(av)) unless av.zero?
      chips << synthese_kpi_chip("Remb.", custom_currency_no_decimals_format(remb)) unless remb.zero?

      admin_synthese_kpi_strip do
        safe_join(chips)
      end
    end
end
