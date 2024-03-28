module CommandesHelper

    def compte_articles(commande)
        if commande 
            commande.articles.sum(:quantite) 
        end
    end

    def du_prix(commande)
        if commande 
            prix_articles = commande.articles.sum(:total)
            prix_sous_articles = commande.articles.joins(:sousarticles).sum('sousarticles.prix')
            prix_articles + prix_sous_articles
        end
    end

    def tva_sur_prix(commande)
        du_prix(commande) * (AdminParameter.first.tx_tva.to_f / 100)
    end

    def du_prix_ht(commande)
        du_prix(commande) - tva_sur_prix(commande)
    end
   
    def du_caution(commande)
        if commande 
            caution_articles = commande.articles.sum(:caution)
            caution_sous_articles = commande.articles.joins(:sousarticles).sum('sousarticles.caution')
            caution_articles + caution_sous_articles
        end 
    end

    def recu_prix(commande)
        commande.paiement_recus.only_prix.sum(:montant)
    end 

    def recu_caution(commande)
        commande.paiement_recus.only_caution.sum(:montant)
    end 

    def avoir_deduit(commande)
        commande.avoir_rembs.avoir_only.sum(:montant)
    end 

    def remb_deduit(commande)
        commande.avoir_rembs.remb_only.sum(:montant)
    end 

    def solde_prix_avant_avoirremb(commande)
        du_prix(commande) - recu_prix(commande) 
    end
    
    def solde_prix(commande)
        du_prix(commande) - recu_prix(commande) - avoir_deduit(commande) + remb_deduit(commande)
    end
    
    def solde_caution(commande)
        du_caution(commande) - recu_caution(commande)
    end

end
