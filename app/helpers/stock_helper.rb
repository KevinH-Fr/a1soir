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
  
  def total_vendus_boutique(produits)
    total_quantite = Article.joins(:produit, :commande)
                            .where(produits: { id: produits })
                          #  .merge(Produit.not_service)
                            .merge(Commande.hors_devis)
                            .where(commandes: { eshop: [false, nil] })
                            .vente_only
                            .sum(:quantite)
  
    total_quantite += Sousarticle.joins(article: :commande)
                                 .joins(:produit)
                                 .where(produits: { id: produits })
                           #      .merge(Produit.not_service)
                                 .merge(Commande.hors_devis)
                                 .where(commandes: { eshop: [false, nil] })
                                 .vente_only
                                 .count
    
    total_quantite
  end
  
  def total_vendus_eshop(produits)
  
   # Stripe payments (only if marked as 'paid')
   total_quantite = StripePaymentItem
   .joins(:stripe_payment)
   .where(stripe_payments: { status: 'paid' }, produit_id: produits)
   .count
    
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
  
      
end
  