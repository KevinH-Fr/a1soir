module ProduitsHelper

    def same_reffrs_same_couleur_others_tailles(produit)
        Produit.where(reffrs: produit.reffrs, couleur_id: produit.couleur_id).where.not(id: produit.id)
    end

    def same_reffrs_same_taille_others_couleurs(produit)
        Produit.where(reffrs: produit.reffrs, taille_id: produit.taille_id).where.not(id: produit.id)
    end

    def badge_prixvente_produit(produit)
        if produit.prixvente
            content_tag(:span, class: "badge fs-6 border border-secondary text-secondary m-1") do
                concat content_tag(:i, "", class: "fa fa-euro me-2")
                concat content_tag(:span, "vente: #{custom_currency_format(produit.prixvente)}")
            end
        end
    end

    def badge_prixlocation_produit(produit)
        if produit.prixlocation
            content_tag(:span, class: "badge fs-6 border border-secondary text-secondary m-1") do
                concat content_tag(:i, "", class: "fa fa-euro me-2")
                concat content_tag(:span, "location: #{custom_currency_format(produit.prixlocation)}")
            end
        end
    end

    def badge_taille_produit(produit)
        if produit.taille
            content_tag(:span, class: "badge fs-6 border border-secondary text-secondary m-1") do
                concat content_tag(:i, "", class: "fa fa-ruler me-2")
                concat content_tag(:span, produit.taille.nom, class: "")
            end
        end
    end
      
    def badge_couleur_produit(produit)
        if produit.couleur
            content_tag(:span, class: "badge fs-6 border border-secondary text-secondary m-1") do
                concat content_tag(:i, "", class: "fa fa-palette me-2")
                concat content_tag(:span, produit.couleur.nom, class: "")
            end
        end
    end

end
 