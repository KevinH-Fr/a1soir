module StockHelper

    def total_produits
        Produit.all.sum(:quantite) 
    end

    def total_loues
        Article.location_only.sum(:quantite)
    end

    def total_vendus
        Article.vente_only.sum(:quantite)
    end

    def produits_restants
        total_produits - total_loues - total_vendus
    end
end
