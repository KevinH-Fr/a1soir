module CommandesHelper

    def compte_articles(commande)
        commande.articles.sum(:quantite)
    end


    def du_prix(commande)
        commande.articles.sum(:total)
        # + Article.joins(:sousarticles).commande_courante(@commande).sum_sousarticles
    end
   
    def du_caution(commande)
        commande.articles.sum(:totalcaution)
        # ajouter sum caution sous articles?
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
