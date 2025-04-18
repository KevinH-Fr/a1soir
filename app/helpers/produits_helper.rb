module ProduitsHelper

    def same_produit_same_couleur_others_tailles(produit)
        Produit.where(handle: produit.handle, couleur_id: produit.couleur_id).where.not(id: produit.id)
    end

    def same_produit_same_taille_others_couleurs(produit)
        Produit.where(handle: produit.handle, taille_id: produit.taille_id).where.not(id: produit.id)
    end

    # with statut disponibilite
    def same_produit_same_couleur_others_tailles_with_statut_disponibilite(produit)
        datedebut = Time.current
        datefin   = Time.current
      
        produits = Produit.actif.where(handle: produit.handle, couleur_id: produit.couleur_id)
                          .where.not(id: produit.id)
      
        produits.select do |p|
          p.statut_disponibilite(datedebut, datefin)[:disponibles] > 0
        end
      end
      
      def same_produit_same_taille_others_couleurs_with_statut_disponibilite(produit)
        datedebut = Time.current
        datefin   = Time.current
      
        produits = Produit.actif.where(handle: produit.handle, taille_id: produit.taille_id)
                          .where.not(id: produit.id)
      
        produits.select do |p|
          p.statut_disponibilite(datedebut, datefin)[:disponibles] > 0
        end
      end

      

    def badge_prixvente_produit(produit)
        if produit.prixvente
            content_tag(:span, class: "badge fs-6 border border-secondary text-secondary m-1 p-1") do
                concat content_tag(:span, "vente : #{custom_currency_no_decimals_format(produit.prixvente)}")
            end
        end
    end

    def badge_prixlocation_produit(produit)
        if produit.prixlocation 
            content_tag(:span, class: "badge fs-6 border border-secondary text-secondary m-1 p-1") do
                concat content_tag(:span, "location : #{custom_currency_no_decimals_format(produit.prixlocation)}")
            end
        end
    end

    def badge_taille_produit(produit)
        if produit.taille
            content_tag(:span, class: "badge fs-6 border border-secondary text-secondary text-uppercase m-1 p-1") do
                concat content_tag(:i, "", class: "bi bi-rulers me-1")
                concat content_tag(:span, produit.taille.nom, class: "")
            end
        end
    end
      
    def badge_couleur_produit(produit)
        if produit.couleur
            content_tag(:span, class: "badge fs-6 border border-secondary text-secondary m-1 p-1") do
                concat color_icon(produit.couleur) if produit.couleur.couleur_code
                concat content_tag(:span, produit.couleur.nom, class: "")
            end
        end
    end

    def is_archived(produit)
        unless produit.actif 
            content_tag(:span, class: "badge fs-6 border border-secondary text-secondary m-1 p-1") do
                concat content_tag(:i, nil, class: "bi bi-archive me-1")
                concat content_tag(:span, "archivé", class: "ms-1" )
            end
        end
    end
    
    def badge_eshop(produit)
        color_status = produit.eshop? ? "text-success" : "text-danger"
        content_tag(:span, class: "badge fs-6 border border-secondary m-1 #{color_status} p-1") do
            concat content_tag(:i, nil, class: "bi bi-house me-1")
            concat content_tag(:span, "eshop", class: "ms-1" )
        end
    end

    
end
 