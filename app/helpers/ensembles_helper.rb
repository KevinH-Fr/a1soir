module EnsemblesHelper
  def type_produits_in_commande(commande)
    # Find locvente values from the commande articles
    locvente_values = commande.articles.pluck(:locvente).uniq
  
    if locvente_values.one?
      # Collect type_produits.nom and produit.reffrs for matching
      commande.articles
              .joins(produit: :type_produit)
              .distinct
              .pluck('type_produits.nom', 'produits.reffrs')
    else
      []
    end
  end


  def find_ensemble_matching_type_produits(commande)
    # Step 1: Fetch type_produits and reffrs from the commande
    type_produits_and_reffrs = type_produits_in_commande(commande)
  
    # Separate type_produits and reffrs into distinct arrays
    type_produits = type_produits_and_reffrs.map(&:first) # Extract type_produits.nom
    reffrs = type_produits_and_reffrs.map(&:last) # Extract produits.reffrs
  
    # Step 2: Filter and match articles with type_produits in the commande
    # Get all type_produits present in the commande articles
    commande_type_produits = commande.articles
                                     .joins(produit: :type_produit)
                                     .pluck('type_produits.nom')
                                     .uniq
  
    # Ensure all type_produits in the ensemble are found in the commande articles
    matching_type_produits = type_produits.select { |tp| commande_type_produits.include?(tp) }
  
    # Proceed if all type_produits are matched
    return [] if matching_type_produits.size != type_produits.size
  
    # Step 3: Build the ensemble query dynamically based on available type_produits
    ensembles = Ensemble.all
      .includes([:type_produit1], [:type_produit2], [:type_produit3], [:type_produit4], [:type_produit5], [:type_produit6])
  
    # Dynamically filter ensembles based on available type_produits
    ensembles = ensembles.select do |ensemble|
      ensemble_type_produits = [
        ensemble.type_produit1&.nom,
        ensemble.type_produit2&.nom,
        ensemble.type_produit3&.nom,
        ensemble.type_produit4&.nom,
        ensemble.type_produit5&.nom,
        ensemble.type_produit6&.nom
      ].compact
  
      # Ensure all ensemble type_produits are included in the matching_type_produits
      (ensemble_type_produits - matching_type_produits).empty?
    end
  
    # ✅ Step 4: Order ensembles by number of matching reffrs
    ordered_ensembles_with_match_count = ensembles.map do |ensemble|
      ensemble_reffrs = [
        ensemble.produit&.reffrs
      ].compact

      # Count how many ensemble reffrs match those in the commande
      match_count = reffrs.count do |commande_reffrs|
        ensemble_reffrs.any? { |ens_reffrs| ens_reffrs.include?(commande_reffrs) }
      end
      
      { ensemble: ensemble, matching_reffrs_count: match_count }
    end

    ordered_ensembles_with_match_count.sort_by! { |e| -e[:matching_reffrs_count] } # descending order

    # ✅ Step 5: Prepare result with matching articles and matching count
    ordered_ensembles_with_match_count.map do |entry|
      ensemble = entry[:ensemble]
      matching_articles = find_matching_articles(commande, ensemble)
  
      {
        ensemble: ensemble,
        matching_articles: matching_articles,
        matching_reffrs_count: entry[:matching_reffrs_count]
      }
    end
  
    #result
  end
  
  

  private

  def find_matching_articles(commande, ensemble)
    # Select articles where the type_produit of the article matches the ensemble's type_produits
    matching_articles = commande.articles
                                .joins(produit: :type_produit)
                                .where(
                                  'type_produits.nom IN (?)',
                                  [
                                    ensemble.type_produit1.nom,
                                    ensemble.type_produit2&.nom,
                                    ensemble.type_produit3&.nom,
                                    ensemble.type_produit4&.nom,
                                    ensemble.type_produit5&.nom,
                                    ensemble.type_produit6&.nom
                                  ]
                                )
    
    # Group by type_produit and select only the first article per type_produit
    unique_articles = matching_articles.group_by { |article| article.produit.type_produit }.map do |_, articles|
      articles.first
    end
  
    unique_articles
  end
  
end
