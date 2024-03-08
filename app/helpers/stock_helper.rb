module StockHelper
    def total_produits(produits)
      if produits.is_a?(Produit)
        produits.quantite.to_i
      elsif produits.is_a?(Enumerable)
        produits.sum(:quantite)
      else
        0
      end
    end
  
    def total_loues(produits)
      if produits.is_a?(Produit)
        total_quantite = produits.articles.location_only.sum(:quantite)
        total_quantite += produits.sousarticles.location_only.count
        total_quantite      
      elsif produits.is_a?(Enumerable)
        produits.map do |produit|
            total_quantite = produit.articles.location_only.sum(:quantite)
            total_quantite += produit.sousarticles.location_only.count
            total_quantite
          end.sum
        else
        0
      end
    end
  
    def total_vendus(produits)
      if produits.is_a?(Produit)
        total_quantite = produits.articles.vente_only.sum(:quantite)
        total_quantite += produits.sousarticles.vente_only.count
        total_quantite
      elsif produits.is_a?(Enumerable)
        produits.map do |produit|
          total_quantite = produit.articles.vente_only.sum(:quantite)
          total_quantite += produit.sousarticles.vente_only.count
          total_quantite
        end.sum
      else
        0
      end
    end
  
    def produits_restants(produits)
      total_produits(produits) - total_loues(produits) - total_vendus(produits)
    end

    def est_disponible(produits)
        if produits_restants(produits) > 0
            true 
        else
            false
        end
    end

    def badge_disponibilite(produits)
        restants = produits_restants(produits)

        if est_disponible(produits)
          content_tag(:span, "Produit disponible - #{restants} restants", class: "badge w-100 fs-4 border border-success text-success")
        else
          content_tag(:span, "Produit indisponible", class: "badge w-100 fs-4 border-danger text-danger")
        end
    end
      
  end
  