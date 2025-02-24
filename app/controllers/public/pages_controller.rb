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

      # # Group produits by handle and pick the first product for each unique handle
      # produits_uniques = @categorie.produits.eshop_diffusion.to_a
      # .group_by(&:handle)
      # .map { |_, produits| produits.first }

      # produits_uniques = Produit.where(id: produits_uniques.map(&:id))
      
      # if params[:taille]
      #   produits_uniques = produits_uniques.where(taille: params[:taille])
      # end

      # Paginate the results
      # @pagy, @produits_uniques = pagy(produits_uniques, items: 6)

      if params[:taille]
        produits = @produits.where(taille: params[:taille])
      else
        produits = @produits
      end

      @pagy, @produits = pagy(produits, items: 6)


      @categories = CategorieProduit.all.order(nom: :asc)

    end

    def produit
      @produit = Produit.find(params[:id])
      @meme_produit_autres_tailles = Produit
      .where(handle: @produit.handle, couleur_id: @produit.couleur_id)
      .where.not(id: @produit.id)
      .joins(:taille)  # Assuming there's a `taille` association on Produit
      .order('tailles.nom')  # Sort by the `nom` field of the `taille` model
    

      #[@produit.taille].compact.uniq
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
