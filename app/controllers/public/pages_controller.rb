module Public
  class PagesController < Public::ApplicationController
    include ProduitsFilterable
    include CabineCartResponder
    
    #layout 'public' 

    def home
      #@categories = CategorieProduit.not_service
      #@carousel_images = Texte&.first&.carousel_images
      @coups_de_coeur = Produit.where(today_availability: true).coups_de_coeur.eshop_diffusion.actif.limit(8)
      #@produits_en_promotion = Produit.where(today_availability: true).en_promotion.eshop_diffusion.actif.limit(10)
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
      @coups_de_coeur = Produit.where(today_availability: true).coups_de_coeur.eshop_diffusion.actif.limit(8)
      session[:from_cabine] = false
    end

    def le_concept
    end

    def nos_autres_activites
    end

    def legal
    end

    def faq
      @texteContact = Texte.last.contact
      @texteHoraire = Texte.last.horaire
      @texteAdresse = Texte.last.adresse
    end

    def cabine_essayage
      session[:from_cabine] = true
      # Initialiser une demande de RDV avec le type "Essayage" pré-sélectionné
      @demande_rdv = DemandeRdv.new
      @demande_rdv.set_type_essayage
    end

    def produits
      # Si le paramètre from_cabine est présent, on active le mode cabine d'essayage
      if params[:from_cabine].present?
        session[:from_cabine] = true
      end
      produits_with_filters
    end

    def produit
      @produit = Produit.find(params[:id])
      
      # Stocker la back_url dans la session si elle est présente dans les params
      # Sinon, utiliser celle de la session pour préserver la navigation entre produits
      if params[:back_url].present?
        session[:produit_back_url] = params[:back_url]
      end
      
      # Utiliser la back_url de la session ou une valeur par défaut
      @back_url = session[:produit_back_url] || produits_index_path
      
      @meme_produit_meme_couleur_autres_tailles = Produit
      .where(handle: @produit.handle, couleur_id: @produit.couleur_id)
      .where.not(id: @produit.id)
      .joins(:taille) 
      .order('tailles.nom') 
    
      @meme_produit_meme_taille_autres_couleurs = Produit
      .where(handle: @produit.handle, taille_id: @produit.taille_id)
      .where.not(id: @produit.id)
      .joins(:couleur) 

      @produits_similaires = @produit.similar_products(limit: 4)
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

      ensure_cabine_cart_session

      if session[:cabine_cart].include?(id)
        flash.now[:notice] = "Ce produit est déjà dans votre cabine d'essayage"
      elsif session[:cabine_cart].size >= 10
        flash.now[:alert] = "Limite de 10 produits atteinte. Retirez un produit pour en ajouter un autre."
      else
        session[:cabine_cart] = (session[:cabine_cart] + [id]).uniq
        flash.now[:success] = "#{@produit.nom} ajouté à votre cabine d'essayage"
      end

      refresh_cabine_cart
      render_cabine_cart_turbo_stream_for(@produit)
    end

    def cabine_remove_product
      id = params[:id].to_i
      @produit = Produit.find(id)
      
      ensure_cabine_cart_session
      session[:cabine_cart] = session[:cabine_cart] - [id]
      flash.now[:info] = "#{@produit.nom} retiré de votre cabine d'essayage"
      
      refresh_cabine_cart
      render_cabine_cart_turbo_stream_for(@produit)
    end

    def cabine_remove_from_cabine
      id = params[:id].to_i
      @produit = Produit.find(id)
      # S'assurer que session[:cabine_cart] existe
      session[:cabine_cart] ||= []
      session[:cabine_cart] = session[:cabine_cart] - [id]
      #flash[:info] = "#{@produit.nom} retiré de votre cabine d'essayage"
      
      redirect_to cabine_essayage_path
    end

    def rdv
      @demande_rdv = DemandeRdv.new
    end

    def contact
      if Texte.last.present?
        @texteContact = Texte.last.contact
        @texteAdresse = Texte.last.adresse
        @texteHoraire = Texte.last.horaire
      end
      @contact_message = ContactMessage.new
    end

  end
end
