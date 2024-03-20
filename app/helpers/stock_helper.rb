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
  
    def produits_restants(produits, date)
      total_produits(produits) - total_loues(produits) - total_vendus(produits)  + locations_terminees_a_date(produits, date)
    end

    def locations_terminees_a_date(produits, date)
      # Count the products with location finished before the given date

      if produits.is_a?(Produit)
        total_quantite = produits.articles.joins(:commande).where("commandes.finloc < ?", date).location_only.sum(:quantite).to_i
        total_quantite += produits.sousarticles.joins(:article => :commande).where("commandes.finloc < ?", date).location_only.count.to_i
        total_quantite
      elsif produits.is_a?(Enumerable)
        produits.map do |produit|
          total_quantite = produit.articles.joins(:commande).where("commandes.finloc < ?", date).location_only.sum(:quantite).to_i
          total_quantite += produit.sousarticles.joins(:article => :commande).where("commandes.finloc < ?", date).location_only.count.to_i
          total_quantite  
        end.sum
      else
        0
      end

    end
    

    # statut des articles
    def articles_loues_in_commandes_non_retires
      Commande.non_retire.sum { |commande| commande.articles.location_only.count }
    end

    def articles_loues_in_commandes_retires
      Commande.retire.sum { |commande| commande.articles.location_only.count }
    end
  
    def articles_loues_in_commandes_rendus
      Commande.rendu.sum { |commande| commande.articles.location_only.count }
    end


    def est_disponible(produits, date)
        if produits_restants(produits, date) > 0
            true 
        else
            false
        end
    end

    def badge_disponibilite(produits, date)
        restants = produits_restants(produits, date)

        if est_disponible(produits, date)
          content_tag(:span, "Produit disponible - #{restants}", class: "badge fs-6 border border-success text-success")
        else
          content_tag(:span, "Produit indisponible", class: "badge fs-6 border border-danger text-danger")
        end
    end
      
  end
  