module Public
  class PagesController < Public::ApplicationController
    include ProduitsFilterable
    include CabineCartResponder
    
    #layout 'public' 

    def home
      @coups_de_coeur = Produit.where(today_availability: true).coups_de_coeur.eshop_diffusion.actif.for_public_listing_cards.limit(8)
      load_periode_speciale_vars
    end

    def la_boutique
      texte = current_texte
      if texte.present?
        @texteContact  = texte.contact
        @texteHoraire  = texte.mode_periode_speciale? ? texte.horaire_periode_speciale : texte.horaire
        @texteBoutique = texte.boutique
        @texteAdresse  = texte.adresse
        @texteEquipe   = texte.equipe
      end
      @google_data = GooglePlacesService.fetch
    end

    def nos_collections
      @coups_de_coeur = Produit.where(today_availability: true).coups_de_coeur.eshop_diffusion.actif.for_public_listing_cards.limit(8)
      session[:from_cabine] = false if session[:cabine_cart].blank?
    end

    def categories
      @categories = CategorieProduit.not_service.includes(image1_attachment: :blob).order(:nom)
      @coups_de_coeur = Produit.where(today_availability: true).coups_de_coeur.eshop_diffusion.actif.for_public_listing_cards.limit(8)
      session[:from_cabine] = false if session[:cabine_cart].blank?
    end

    def le_concept
    end

    def nos_autres_activites
    end

    def festival_de_cannes
      texte = current_texte
      if texte.present?
        @texteContact = texte.contact
        @texteHoraire = texte.mode_periode_speciale? ? texte.horaire_periode_speciale : texte.horaire
        @texteAdresse = texte.adresse
      end

      offer_sheets =
        if I18n.locale == :en
          {
            offer_sheet_1_url: "https://res.cloudinary.com/dukne3lhz/image/upload/v1778424806/WhatsApp_Image_2026-05-10_at_16.15.31_2_fifemk.jpg",
            offer_sheet_2_url: "https://res.cloudinary.com/dukne3lhz/image/upload/v1778424806/WhatsApp_Image_2026-05-10_at_16.15.31_3_ubusx0.jpg"
          }
        else
          {
            offer_sheet_1_url: "https://res.cloudinary.com/dukne3lhz/image/upload/v1778424535/WhatsApp_Image_2026-05-10_at_16.15.31_x7htic.jpg",
            offer_sheet_2_url: "https://res.cloudinary.com/dukne3lhz/image/upload/v1778424535/WhatsApp_Image_2026-05-10_at_16.15.31_1_vdv9ww.jpg"
          }
        end

      @festival_media = offer_sheets.merge(
        header_image_1_url: "https://res.cloudinary.com/dukne3lhz/image/upload/v1778424535/WhatsApp_Image_2026-05-10_at_16.15.31_5_iy6io3.jpg",
        header_image_2_url: "https://res.cloudinary.com/dukne3lhz/image/upload/v1778424535/WhatsApp_Image_2026-05-10_at_16.16.35_xyakfo.jpg",
        social_proof_image_url: "https://res.cloudinary.com/dukne3lhz/image/upload/v1778424535/WhatsApp_Image_2026-05-10_at_16.15.31_5_iy6io3.jpg",
        video_url: "https://res.cloudinary.com/dukne3lhz/video/upload/v1778495070/Festival_2026_Reel_Instagram_xgmvwd.mp4",
        video_poster_url: "https://res.cloudinary.com/dukne3lhz/image/upload/v1778424535/WhatsApp_Image_2026-05-10_at_16.16.35_xyakfo.jpg",
        whatsapp_visual_url: "https://res.cloudinary.com/dukne3lhz/image/upload/v1778424535/WhatsApp_Image_2026-05-10_at_16.16.01_2_osynga.jpg"
      )

      load_periode_speciale_vars
    end

    def legal
    end

    def faq
      texte = current_texte
      if texte.present?
        @texteContact = texte.contact
        @texteHoraire = texte.horaire
        @texteAdresse = texte.adresse
      end
    end

    def cabine_essayage
      session[:from_cabine] = true
      @demande_rdv = DemandeRdv.new
      @demande_rdv.set_type_essayage
      load_periode_speciale_vars
    end

    def produits
      session[:from_cabine] = params[:from_cabine].present?
      produits_with_filters
    end

    def produit
      @produit = Produit.for_public_listing_cards
                        .includes(:taille, :couleur, :categorie_produits)
                        .find(params[:id])
      
      expected_slug = @produit.handle.presence || @produit.nom.parameterize

      if params[:slug] != expected_slug
        return redirect_to(
          produit_path(slug: expected_slug, id: @produit.id),
          status: :moved_permanently
        )
      end

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
        .where(today_availability: true)
        .includes(:taille)
        .joins(:taille)
        .order("tailles.nom")

      @meme_produit_meme_taille_autres_couleurs = Produit
        .where(handle: @produit.handle, taille_id: @produit.taille_id)
        .where.not(id: @produit.id)
        .where(today_availability: true)
        .includes(:couleur)
        .joins(:couleur)

      @produits_similaires = @produit.similar_products(limit: 4).merge(Produit.for_public_listing_cards)
    end

    
    def update_filters
      session[:from_cabine] = params[:from_cabine].present?
      update_filters_turbo
    end
    
    def cart
      @total_amount = @cart.sum { |item| item.prixvente }
    end

    def transfer_cart_to_cabine
      if @cart.blank?
        redirect_to cart_path, alert: t("public.pages.cart.empty_title")
        return
      end

      session[:cabine_cart] ||= []
      combined = (session[:cabine_cart] + session[:cart]).uniq

      if combined.size > 10
        redirect_to cart_path, alert: t("public.pages.cabine_essayage.flash.limit_reached")
        return
      end

      transferred_count = @cart.size
      session[:cabine_cart] = combined
      session[:cart] = []
      session[:from_cabine] = true

      redirect_to cabine_essayage_path,
                  notice: t("public.pages.cart.transfer_to_cabine_success", count: transferred_count)
    end

    def cabine_add_product
      id = params[:id].to_i
      @produit = Produit.find(id)

      ensure_cabine_cart_session

      if session[:cabine_cart].include?(id)
        flash.now[:notice] = t("public.pages.cabine_essayage.flash.already_in_cart")
      elsif session[:cabine_cart].size >= 10
        flash.now[:alert] = t("public.pages.cabine_essayage.flash.limit_reached")
      else
        session[:cabine_cart] = (session[:cabine_cart] + [id]).uniq
        flash.now[:success] = t("public.pages.cabine_essayage.flash.added", product_name: @produit.nom)
      end

      refresh_cabine_cart
      render_cabine_cart_turbo_stream_for(@produit)
    end

    def cabine_remove_product
      id = params[:id].to_i
      @produit = Produit.find(id)
      
      ensure_cabine_cart_session
      session[:cabine_cart] = session[:cabine_cart] - [id]
      flash.now[:info] = t("public.pages.cabine_essayage.flash.removed", product_name: @produit.nom)
      
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
      load_periode_speciale_vars
    end

    def contact
      texte = current_texte
      if texte.present?
        @texteContact = texte.contact
        @texteAdresse = texte.adresse
        @texteHoraire = texte.horaire
      end
      @contact_message = ContactMessage.new
    end

    private

    def load_periode_speciale_vars
      texte = current_texte
      return unless texte&.mode_periode_speciale?
      @mode_periode_speciale   = true
      @encart_periode_speciale = I18n.locale == :fr ? texte.encart_periode_speciale_fr : texte.encart_periode_speciale_en
    end

  end
end
