module StockHelper

   # sans dates
  def total_produits(produits)
    Produit.where(id: produits).not_service.sum(:quantite)    
  end
  
  def total_services(produits)
    Produit.where(id: produits).is_service.sum(:quantite)    
  end
    
  def total_loues(produits)
    total_quantite = Article.joins(:produit, :commande)
                            .where(produits: { id: produits })
                            .merge(Commande.hors_devis)
                            .location_only
                            .sum(:quantite)
  
    total_quantite += Sousarticle.joins(article: :commande)
                                 .joins(:produit)
                                 .where(produits: { id: produits })
                                 .merge(Commande.hors_devis)
                                 .location_only
                                 .count
  
    total_quantite
  end
  
  def total_vendus(produits)
    total_quantite = Article.joins(:produit, :commande)
                            .where(produits: { id: produits })
                          #  .merge(Produit.not_service)
                            .merge(Commande.hors_devis)
                            .vente_only
                            .sum(:quantite)
  
    total_quantite += Sousarticle.joins(article: :commande)
                                 .joins(:produit)
                                 .where(produits: { id: produits })
                           #      .merge(Produit.not_service)
                                 .merge(Commande.hors_devis)
                                 .vente_only
                                 .count
    
    total_quantite
  end
  
  def total_vendus_eshop(produits)
  
   # Stripe payments (only if marked as 'paid')
    total_quantite = StripePayment
    .where(produit_id: produits, status: 'paid')
    .count
    
    total_quantite
  end


  # def statut_disponibilite(produits, datedebut, datefin)
    
  #   if Produit.is_service.exists?(id: produits) || Produit.is_ensemble.exists?(id: produits)
  #     initial_stock = 1
  #     loues_a_date = 0
  #     vendus = 0
  #     disponibles = 1
  #   else
  #     loues_a_date = Article.joins(:commande)
  #                          .where(produit_id: produits)
  #                          .where("commandes.debutloc <= ? AND commandes.finloc >= ?", datedebut, datefin)
  #                          .merge(Commande.hors_devis)                         
  #                          .location_only.sum(:quantite).to_i
  
  #     loues_a_date += Sousarticle.joins(article: :commande)
  #                          .where(produit_id: produits)
  #                          .merge(Commande.hors_devis)
  #                          .where("commandes.debutloc <= ? AND commandes.finloc >= ?", datedebut, datefin)
  #                          .location_only.sum(:quantite).to_i

  #     initial_stock = total_produits(produits)
  #     vendus = total_vendus(produits)
  #   end

  #   disponibles = initial_stock - (loues_a_date + vendus)
  
  #   # Ensure we are returning a hash with all the necessary keys
  #   {
  #     produit_id: produits.id,
  #     nom: produits.nom,
  #     datedebut: datedebut,
  #     datefin: datefin,
  #     initial: initial_stock,
  #     loues_a_date: loues_a_date,
  #     vendus: vendus,
  #     disponibles: disponibles,
  #     statut: disponibles > 0 ? "disponible" : "indisponible"
  #   }
  # end
  


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
  
      
end
  