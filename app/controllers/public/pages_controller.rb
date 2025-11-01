module Public
  class PagesController < ApplicationController
    include ProduitsFilterable
    
    layout 'public' 

    def home
      #@categories = CategorieProduit.not_service
      #@carousel_images = Texte&.first&.carousel_images
    end

    def la_boutique
      if Texte.last.present?
        @texteContact = Texte.last.contact
        @texteHoraire = Texte.last.horaire
        @texteBoutique = Texte.last.boutique
        @texteAdresse = Texte.last.adresse
        @texteEquipe = Texte.last.equipe
      end
    end

    def nos_collections
    end

    def le_concept
    end

    def nos_autres_activites
    end

    def legal
    end

    def faq
    end

    # def categories
    #   @categories = CategorieProduit.all
    # end

    def produits
      produits_with_filters
    end
    

    def update_filters
      update_filters_turbo
    end
    
    # def produit
    #   @produit = Produit.find(params[:id])
    #   @meme_produit_meme_couleur_autres_tailles = Produit
    #   .where(handle: @produit.handle, couleur_id: @produit.couleur_id)
    #   .where.not(id: @produit.id)
    #   .joins(:taille) 
    #   .order('tailles.nom') 
    
    #   @meme_produit_meme_taille_autres_couleurs = Produit
    #   .where(handle: @produit.handle, taille_id: @produit.taille_id)
    #   .where.not(id: @produit.id)
    #   .joins(:couleur) 

    # end

    def cart
      @total_amount = @cart.sum { |item| item.prixvente } # Sum of all item prices
    end

    def contact
      if Texte.last.present?
        @texteContact = Texte.last.contact
        @texteAdresse = Texte.last.adresse
        @texteHoraire = Texte.last.horaire
      end
    end

    #def cgv  
    #end

    #def rdv
    #end

  end
end
