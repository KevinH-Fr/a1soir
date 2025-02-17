module Public
  class PagesController < ApplicationController
    layout 'public' 

    def home
      @categories = CategorieProduit.all
    end

    def categories
      @categories = CategorieProduit.all
    end

    def categorie
      @categorie = CategorieProduit.find(params[:id])
      @produits = @categorie.produits.eshop_diffusion

      # Group produits by handle and pick the first product for each unique handle
      @produits_uniques = @produits.group_by(&:handle).map { |_, produits| produits.first }

      @toutes_tailles_categorie = @produits.map { |produit| produit.taille }.compact.uniq

      @categories = CategorieProduit.all


    end

    def display_taille_selected
      @categorie = CategorieProduit.find(params[:categorie])
      @produits = @categorie.produits.eshop_diffusion
      @toutes_tailles_categorie =  @produits.map { |produit| produit.taille }.compact.uniq

      if params[:taille].present?
        @produits = @produits.joins(:taille).where(tailles: { nom: params[:taille] })
      end

      # Group produits by handle and pick the first product for each unique handle
      @produits_uniques = @produits.group_by(&:handle).map { |_, produits| produits.first }
            
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(
             'partial-taille-selected', partial: 'public/pages/taille_selected'
            )
          ]
        end
      end    
  
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
