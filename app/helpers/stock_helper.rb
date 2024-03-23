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
  
    def produits_restants(produits, date = Date.today)
      total_produits(produits) - total_loues(produits) - total_vendus(produits)  + locations_terminees_a_date(produits,  date = Date.today)
    end

    def locations_terminees_a_date(produits,  date = Date.today)
      # Count the products with locations finished before the given date and the status of the command is "rendu"
    
      if produits.is_a?(Produit)
        total_quantite = produits.articles.joins(:commande).where("commandes.finloc < ? AND commandes.statutarticles = ?", date, "rendu").location_only.sum(:quantite).to_i
        total_quantite += produits.sousarticles.joins(:article => :commande).where("commandes.finloc < ? AND commandes.statutarticles = ?", date, "rendu").location_only.count.to_i
        total_quantite
      elsif produits.is_a?(Enumerable)
        produits.map do |produit|
          total_quantite = produit.articles.joins(:commande).where("commandes.finloc < ? AND commandes.statutarticles = ?", date, "rendu").location_only.sum(:quantite).to_i
          total_quantite += produit.sousarticles.joins(:article => :commande).where("commandes.finloc < ? AND commandes.statutarticles = ?", date, "rendu").location_only.count.to_i
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


    def est_disponible(produits, date = Date.today)

        if produits_restants(produits,  date = Date.today) > 0
            true 
        else
            false
        end
    end

    def badge_disponibilite(produits, date = Date.today)
        restants = produits_restants(produits,  date = Date.today)

        if est_disponible(produits,  date = Date.today)
          content_tag(:span, "Produit disponible - #{restants}", class: "badge fs-6 border border-success text-success")
        else
          content_tag(:span, "Produit indisponible", class: "badge fs-6 border border-danger text-danger")
        end
    end
      
  end
  