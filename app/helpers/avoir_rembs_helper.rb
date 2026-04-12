module AvoirRembsHelper

    def badges_avoirrembs_synthese(commande)
      av = avoir_deduit(commande).to_d
      remb = remb_deduit(commande).to_d

      chips = []
      chips << synthese_kpi_chip("Avoir", custom_currency_no_decimals_format(av)) unless av.zero?
      chips << synthese_kpi_chip("Rembours.", custom_currency_no_decimals_format(remb)) unless remb.zero?

      content_tag(:div, class: "d-flex flex-wrap gap-2 align-items-center justify-content-end mw-100") do
        safe_join(chips)
      end
    end
end
