module EnsemblesHelper

    def type_produits_in_commande(commande)
        commande.articles.joins(:produit => :type_produit).distinct.pluck('type_produits.nom')
    end


    def find_ensemble_matching_type_produits(commande)
        type_produits = type_produits_in_commande(commande)
    
        ensemble = Ensemble.find_by(
            type_produit1: TypeProduit.where(nom: type_produits),
            type_produit2: TypeProduit.where(nom: type_produits)

        )
    
        ensemble
      end

end
