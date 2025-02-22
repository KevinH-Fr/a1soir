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
      
      # # Group produits by handle and pick the first product for each unique handle
      produits_uniques = @categorie.produits.eshop_diffusion.to_a
      .group_by(&:handle)
      .map { |_, produits| produits.first }

      produits_uniques = Produit.where(id: produits_uniques.map(&:id))
      
      if params[:taille]
        produits_uniques = produits_uniques.where(taille: params[:taille])
      end

      # Paginate the results
      @pagy, @produits_uniques = pagy(produits_uniques, items: 6)

      @toutes_tailles_categorie = @produits.map { |produit| produit.taille }.compact.uniq.sort_by(&:nom)

      @categories = CategorieProduit.all.order(nom: :asc)

    end

    def produit
      @produit = Produit.find(params[:id])
      @tailles = [@produit.taille].compact.uniq
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
