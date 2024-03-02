module ArticlesHelper
    def badges_articles_synthese(articles)

      commande = articles.first.commande if articles.first
      content_tag(:div, class: "container-fluid text-center") do
        concat(content_tag(:span, class: "badge fs-5 bg-secondary mx-1") do
          concat("Articles: ")
          concat(content_tag(:span,  compte_articles(commande).to_i, class: ""))
        end)
  
        concat(content_tag(:span, class: "badge fs-5 bg-secondary mx-1") do
          concat("Prix: ")
          concat(content_tag(:span, custom_currency_format(du_prix(commande)), class: ""))
        end)

        concat(content_tag(:span, class: "badge fs-5 bg-secondary mx-1") do
            concat("Caution: ")
            concat(content_tag(:span, custom_currency_format(du_caution(commande)), class: ""))
        end)

      end
    end
  end
  