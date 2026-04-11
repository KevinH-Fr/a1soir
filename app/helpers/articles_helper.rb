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
        concat(content_tag(:span, custom_currency_format(du_prix(commande)), class: ""))
      end)

      concat(content_tag(:span, class: "badge fs-6 bg-secondary mx-1") do
          concat("Caution: ")
          concat(content_tag(:span, custom_currency_no_decimals_format(du_caution(commande)), class: ""))
      end)

    end
  end

  def produit_selection(produit, commande)
    statut = produit.statut_disponibilite(commande.debutloc&.to_date, commande.finloc&.to_date)
    disponibles = statut[:disponibles]
    selection_path = admin_selection_produit_path(produit: produit, article: @article)

    select_btn = if disponibles > 0
      content_tag(:div, class: "mt-3 pt-3 border-top border-secondary-subtle") do
        link_to(selection_path,
                class: "btn btn-primary rounded-3 px-4 py-2 fw-semibold shadow-sm w-100 d-inline-flex align-items-center justify-content-center gap-2") do
          safe_join([
            content_tag(:i, "", class: "bi bi-check2", aria: { hidden: true }),
            "Sélectionner"
          ])
        end
      end
    else
      "".html_safe
    end

    card_content = content_tag(:div, class: "row g-0") do
      content_tag(:div, class: "col-4 d-flex align-items-center") do
        image_tag(produit.default_image, class: "img-fluid")
      end +
        content_tag(:div, class: "col-8 d-flex align-items-center") do
          content_tag(:div, class: "card-body") do
            content_tag(:h4, produit.full_name, class: "card-title") +
              content_tag(:p, produit.description) +
              badge_taille_produit(produit) +
              badge_couleur_produit(produit) +
              badge_prixlocation_produit(produit) +
              badge_prixvente_produit(produit) +
              content_tag(:p, class: "m-1 mt-3 fs-5 mb-0") do
                content_tag(:span, " Disponibles: #{disponibles}", class: "badge #{disponibles > 0 ? 'bg-success' : 'bg-danger'}")
              end +
              select_btn
          end
        end
    end

    content_tag(:div, class: "card shadow-sm mb-3 w-100") do
      card_content
    end
  end

  

end
  