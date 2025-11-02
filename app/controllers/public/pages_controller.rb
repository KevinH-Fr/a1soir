module Public
  class PagesController < Public::ApplicationController
    include ProduitsFilterable
    
    #layout 'public' 

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

    def cabine_essayage
      session[:from_cabine] = true
    end

    def produits
      # Si le paramètre from_cabine est présent, on active le mode cabine d'essayage
      if params[:from_cabine].present?
        session[:from_cabine] = true
      end
      produits_with_filters
    end
    
    
    def update_filters
      # Si le paramètre from_cabine est présent, on active le mode cabine d'essayage
      if params[:from_cabine].present?
        session[:from_cabine] = true
      end
      update_filters_turbo
    end
    
    def cart
      @total_amount = @cart.sum { |item| item.prixvente } # Sum of all item prices
    end

    def cabine_add_product
      id = params[:id].to_i
      @produit = Produit.find(id)
            
      respond_to do |format|
        if session[:cabine_cart].include?(id)
          flash[:notice] = "Ce produit est déjà dans votre cabine d'essayage"
          format.turbo_stream
        elsif session[:cabine_cart].size >= 10
          flash[:alert] = "Limite de 10 produits atteinte. Retirez un produit pour en ajouter un autre."
          format.turbo_stream
        else
          session[:cabine_cart] << id
          flash[:success] = "#{@produit.nom} ajouté à votre cabine d'essayage"
          format.turbo_stream
        end
      end
    end

    def cabine_remove_product
      id = params[:id].to_i
      @produit = Produit.find(id)
      session[:cabine_cart].delete(id)
      flash[:info] = "#{@produit.nom} retiré de votre cabine d'essayage"
      
      respond_to do |format|
        format.turbo_stream
      end
    end

    def cabine_remove_from_cabine
      id = params[:id].to_i
      @produit = Produit.find(id)
      session[:cabine_cart].delete(id)
      #flash[:info] = "#{@produit.nom} retiré de votre cabine d'essayage"
      
      redirect_to cabine_essayage_path
    end

    def contact
      if Texte.last.present?
        @texteContact = Texte.last.contact
        @texteAdresse = Texte.last.adresse
        @texteHoraire = Texte.last.horaire
      end
    end

  end
end
