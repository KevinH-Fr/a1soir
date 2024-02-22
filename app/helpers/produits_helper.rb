module ProduitsHelper

    #faire helper pour trouver les produits similaire avec autre couleur ou autre taille
    # voir comment était fait avant : sur reffrs 

    def same_reffrs_same_couleur_others_tailles(produit)
        Produit.where(reffrs: produit.reffrs, couleur_id: produit.couleur_id).where.not(id: produit.id)
    end

    def same_reffrs_same_taille_others_couleurs(produit)
        Produit.where(reffrs: produit.reffrs, taille_id: produit.taille_id).where.not(id: produit.id)
    end
end
 