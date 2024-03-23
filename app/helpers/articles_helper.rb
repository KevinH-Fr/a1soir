module ArticlesHelper
  def badges_articles_synthese(articles)

    commande = articles.first.commande if articles.first
    content_tag(:div, class: "container-fluid text-center") do
      concat(content_tag(:span, class: "badge fs-6 bg-secondary mx-1") do
        concat("Articles: ")
        concat(content_tag(:span,  compte_articles(commande).to_i, class: ""))
      end)

      concat(content_tag(:span, class: "badge fs-6 bg-secondary mx-1") do
        concat("Prix: ")
        concat(content_tag(:span, custom_currency_no_decimals_format(du_prix(commande)), class: ""))
      end)

      concat(content_tag(:span, class: "badge fs-6 bg-secondary mx-1") do
          concat("Caution: ")
          concat(content_tag(:span, custom_currency_no_decimals_format(du_caution(commande)), class: ""))
      end)

    end
  end

  def produit_selection(produit, commande)
    content_tag(:div, class: "card shadow-sm mb-3") do
      content_tag(:div, class: "row g-0") do
        content_tag(:div, class: "col-4") do
          image_tag(produit.default_image, class: "img-produit")
        end +
        content_tag(:div, class: "col-8 d-flex align-items-center") do
          content_tag(:div, class: "card-body") do
            content_tag(:h4, produit.full_name, class: "card-title") +
            content_tag(:p, produit.description) +

            badge_taille_produit(produit) +
            badge_couleur_produit(produit) +

            badge_prixlocation_produit(produit) +
            badge_prixvente_produit(produit) +



            content_tag(:p, badge_disponibilite(produit, commande.debutloc&.to_date), class: "m-1 mt-3") 
          end
        end
      end
    end
  end

end
  