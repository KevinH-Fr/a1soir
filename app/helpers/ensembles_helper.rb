module EnsemblesHelper

    def type_produits_in_commande(commande)
      # trouver les type produits de la commande avec même locvente value
      locvente_values = commande.articles.pluck(:locvente).uniq
      locvente_values.one? ? commande.articles.joins(produit: :type_produit).distinct.pluck('type_produits.nom') : []
    end
  
    def find_ensemble_matching_type_produits(commande)
      type_produits = type_produits_in_commande(commande)
  
      ensemble = Ensemble.find_by(
        type_produit1: TypeProduit.where(nom: type_produits),
        type_produit2: TypeProduit.where(nom: type_produits)
      )
  
        if ensemble
          matching_articles = find_matching_articles(commande, ensemble)
          { ensemble: ensemble, matching_articles: matching_articles }
        end 
    end
  
    private
  
    def find_matching_articles(commande, ensemble)
      commande.articles.joins(:produit => :type_produit)
                      .where('type_produits.nom IN (?)', 
                      [ensemble.type_produit1.nom, ensemble.type_produit2&.nom, 
                       ensemble.type_produit3&.nom, ensemble.type_produit4&.nom, 
                       ensemble.type_produit5&.nom, ensemble.type_produit6&.nom ])
    end
  
  end
  