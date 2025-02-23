module Public
  class PagesController < ApplicationController
    layout 'public' 

    def home
      @categories = CategorieProduit.all
    end

    def categories
      @categories = CategorieProduit.all
    end

    def produits
      @categorie = CategorieProduit.find(params[:id])

      @produits = @categorie.produits.eshop_diffusion
      @toutes_tailles_categorie = @produits.map { |produit| produit.taille }.compact.uniq.sort_by(&:nom)

      if params[:taille]
        produits = @produits.where(taille: params[:taille])
      else
        # Group produits by handle and pick the first product for each unique handle
        produits_uniques = @produits
        .group_by { |produit| [produit.handle, produit.couleur] } # Group by handle and couleur
        .map { |_, produits| produits.first }
      
        produits = Produit.where(id: produits_uniques.map(&:id))
       
      end

      @pagy, @produits = pagy(produits, items: 6)

      @categories = CategorieProduit.all.order(nom: :asc)

    end

    def produit
      @produit = Produit.find(params[:id])
      @meme_produit_meme_couleur_autres_tailles = Produit
      .where(handle: @produit.handle, couleur_id: @produit.couleur_id)
      .where.not(id: @produit.id)
      .joins(:taille) 
      .order('tailles.nom') 
    
      @meme_produit_meme_taille_autres_couleurs = Produit
      .where(handle: @produit.handle, taille_id: @produit.taille_id)
      .where.not(id: @produit.id)
      .joins(:couleur) 

    end

    def contact
      if Texte.last.present?
        @texteContact = Texte.last.contact
        @texteAdresse = Texte.last.adresse
      end
    end

    def cgv  
    end

    def rdv
    end

    def laboutique
      if Texte.last.present?
        @texteContact = Texte.last.contact
        @texteHoraire = Texte.last.horaire
        @texteBoutique = Texte.last.boutique
        @texteAdresse = Texte.last.adresse
      end
    end

  end
end
