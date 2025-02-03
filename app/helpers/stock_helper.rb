module StockHelper

  def total_produits(produits)
    Produit.where(id: produits).not_service.sum(:quantite)    
  end
  
  def total_services(produits)
    Produit.where(id: produits).is_service.sum(:quantite)    
  end
    
  def total_loues(produits)
    total_quantite = Article.joins(:produit).where(produits: { id: produits }).location_only.sum(:quantite)
    total_quantite += Sousarticle.joins(:produit).where(produits: { id: produits }).location_only.count
    total_quantite
  end
  
  def total_vendus(produits)
    total_quantite = Article.joins(:produit).where(produits: { id: produits }).merge(Produit.not_service).vente_only.sum(:quantite)
    total_quantite += Sousarticle.joins(:produit).where(produits: { id: produits }).merge(Produit.not_service).vente_only.count
    total_quantite
  end
  
  

  def produits_restants(produits, date = Date.today)
    if Produit.is_ensemble.exists?(id: produits) 
      1 # defaut stock for ensemble
    else
      total_produits(produits) - total_loues(produits) - total_vendus(produits) + locations_terminees_a_date(produits, date)
    end
  end
    
  def locations_terminees_a_date(produits,  date = Date.today)

    #only check status rendu, not end date of location
    total_quantite = Article.joins(:commande)
      .where(commande: { statutarticles: "rendu" }, produit_id: produits)
      .location_only.sum(:quantite).to_i

    total_quantite += Sousarticle.joins(article: :commande)
      .where(commandes: { statutarticles: "rendu" })
      .where(produit_id: produits).location_only.sum(:quantite).to_i

    total_quantite
  end
    
  # statut des articles
  def articles_loues_in_commandes_non_retires
    Commande.non_retire.sum { |commande| commande.articles.location_only.sum(:quantite) }
  end

  def articles_loues_in_commandes_retires
    Commande.retire.sum { |commande| commande.articles.location_only.sum(:quantite) }
  end

  def articles_loues_in_commandes_rendus
    Commande.rendu.sum { |commande| commande.articles.location_only.sum(:quantite) }
  end

  def articles_services_in_commandes
    total_count = 0
    Commande.all.each do |commande|
      articles_count = commande.articles.service_only.count
      sousarticles_count = commande.articles.map { |article| article.sousarticles.service_only.count }.sum
      total_count += articles_count + sousarticles_count
    end
    total_count
  end
  

  def est_disponible(produits, date = Date.today)
    unless is_archived(produits)
      produits_restants(produits, date) > 0 || Produit.where(id: produits).is_service.exists?
    end
  end
  

  def badge_disponibilite(produits, date = Date.today)
    if Produit.where(id: produits).is_service.exists?
      restants = 1
    else 
      restants = produits_restants(produits,  date = Date.today)
    end

    if est_disponible(produits,  date = Date.today)
      content_tag(:span, "Disponibles : #{restants}", class: "badge fs-6 border border-success text-success")
    else
      content_tag(:span, "Indisponible", class: "badge fs-6 border border-danger text-danger")
    end
  end
      
end
  