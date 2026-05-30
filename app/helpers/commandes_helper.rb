module CommandesHelper
    # Badge visible liste commandes / fiche
    def commande_eshop_badge(commande)
      return "".html_safe unless commande&.eshop?

      content_tag(:span,
                  class: "badge border border-warning text-dark fw-semibold m-1 shadow-sm",
                  title: "Commande issue du site e-shop (paiement Stripe)") do
        concat content_tag(:i, nil, class: "bi bi-cart-check me-1")
        concat "E-shop"
      end
    end

    def commande_remboursee_badge(commande)
      return "".html_safe unless commande&.remboursee_eshop?

      content_tag(:span,
                  class: "badge border border-danger text-danger fw-semibold m-1 shadow-sm",
                  title: t("commandes.eshop_remboursement.badge_title")) do
        concat content_tag(:i, nil, class: "bi bi-arrow-counterclockwise me-1")
        concat t("commandes.eshop_remboursement.badge")
      end
    end

    def pdf_afficher_annulation_eshop?(commande, doc_edition)
      doc_edition.doc_type == "facture" && commande.remboursee_eshop?
    end

    def pdf_titre_document(commande, doc_edition)
      return t("document_types.facture") if doc_edition.doc_type == "facture"
      return "Devis" if commande.devis?

      doc_edition.doc_type.to_s.capitalize
    end

    # Totaux : si les associations sont déjà préchargées (PDF via load_doc_edition_for_pdf!),
    # on calcule en mémoire pour éviter des SUM SQL répétés dans les partials.
    def compte_articles(commande)
        return unless commande

        if commande.association(:articles).loaded?
          commande.articles.sum(&:quantite)
        else
          commande.articles.sum(:quantite)
        end
    end

    def du_prix(commande)
        return unless commande

        if commande.association(:articles).loaded?
          prix_articles = commande.articles.sum { |a| a.total.to_d }
          prix_sous_articles = commande.articles.flat_map(&:sousarticles).sum { |s| s.prix.to_d }
        else
          prix_articles = commande.articles.sum(:total)
          prix_sous_articles = commande.articles.joins(:sousarticles).sum("sousarticles.prix")
        end
        frais_livraison = commande.stripe_payment&.frais_livraison_centimes.to_d / 100
        (prix_articles + prix_sous_articles + frais_livraison).round(2)
    end

    def du_prix_ht(commande)
        prix_ht = du_prix(commande) /  ( 1 + (AdminParameter.first.tx_tva.to_f / 100 ) )
        prix_ht.round(2)
    end

    def tva_sur_prix(commande)
        tva = du_prix(commande) - du_prix_ht(commande)
        tva.round(2)
    end
   
    def du_caution(commande)
        return unless commande

        if commande.association(:articles).loaded?
          caution_articles = commande.articles.sum { |a| a.caution.to_d }
          caution_sous_articles = commande.articles.flat_map(&:sousarticles).sum { |s| s.caution.to_d }
        else
          caution_articles = commande.articles.sum(:caution)
          caution_sous_articles = commande.articles.joins(:sousarticles).sum("sousarticles.caution")
        end
        caution_articles + caution_sous_articles
    end

    def recu_prix(commande)
        return 0 unless commande

        manuel = if commande.association(:paiement_recus).loaded?
                   commande.paiement_recus.select { |p| p.typepaiement == "prix" }.sum { |p| p.montant.to_d }
                 else
                   commande.paiement_recus.only_prix.sum(:montant).to_d
                 end
        stripe = recu_prix_stripe_euros(commande)
        (manuel + stripe).round(2)
    end

    # Paiement Checkout Stripe lié à la commande (non dupliqué dans paiement_recus)
    def recu_prix_stripe_euros(commande)
        sp = commande.stripe_payment
        return 0.to_d if sp.blank? || sp.status != "paid" || sp.amount.blank?

        sp.amount.to_d / 100
    end

    def frais_livraison_stripe_euros(commande)
        commande.stripe_payment&.frais_livraison_centimes.to_d / 100
    end

    def pdf_afficher_paiements?(commande)
        return false unless commande

        commande.paiement_recus.present? ||
          (commande.eshop? && commande.stripe_payment&.status == "paid")
    end

    def pdf_afficher_livraison?(commande)
        commande&.eshop? && commande.stripe_payment.present?
    end

    def recu_caution(commande)
        if commande.association(:paiement_recus).loaded?
          commande.paiement_recus.select { |p| p.typepaiement == "caution" }.sum { |p| p.montant.to_d }
        else
          commande.paiement_recus.only_caution.sum(:montant)
        end
    end 

    def avoir_deduit(commande)
        if commande.association(:avoir_rembs).loaded?
          commande.avoir_rembs.select { |a| a.type_avoir_remb == "avoir" }.sum { |a| a.montant.to_d }
        else
          commande.avoir_rembs.avoir_only.sum(:montant)
        end
    end 

    def remb_deduit(commande)
        if commande.association(:avoir_rembs).loaded?
          commande.avoir_rembs.select { |a| a.type_avoir_remb == "remboursement" }.sum { |a| a.montant.to_d }
        else
          commande.avoir_rembs.remb_only.sum(:montant)
        end
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
