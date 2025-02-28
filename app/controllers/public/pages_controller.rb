module Public
  class PagesController < ApplicationController
    layout 'public' 

    def home
      @categories = CategorieProduit.all
      @carousel_images = Texte&.first&.carousel_images
    end

    def categories
      @categories = CategorieProduit.all
    end

    def produits
      # Determine the category and associated produits
      if params[:id].present?
        @categorie = CategorieProduit.find(params[:id])
        @produits = @categorie.produits.eshop_diffusion
      else
        @produits = Produit.all.eshop_diffusion
      end
     
      @toutes_tailles = @produits.map(&:taille).compact.uniq.sort_by(&:nom)
      @toutes_couleurs = @produits.map(&:couleur).compact.uniq.sort_by(&:nom)
    
      # Filter by taille if provided, otherwise group by handle and couleur
      if params[:taille].present?
        produits = @produits.where(taille: params[:taille], couleur: params[:couleur])
      else
        produits_uniques = @produits
          .group_by { |produit| [produit.handle, produit.couleur] } # Group by handle and couleur
          .map { |_, produits| produits.first }
        produits = Produit.where(id: produits_uniques.map(&:id))
      end
    
      # Filter by couelur if provided, 
      # if params[:couleur].present?
      #   produits = @produits.where(couleur: params[:couleur])
      #   puts " ____________ couleur is set : #{params[:couleur]} lsite: #{@produits.ids} ___________"

      # end
      
      search_params = params.permit(:format, :page, 
        q:[:nom_or_description_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_cont])

      @q = produits.ransack(search_params[:q])
      produits = @q.result(distinct: true).order(nom: :asc)

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
