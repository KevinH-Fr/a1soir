module Public
  class DemandeRdvController < Public::ApplicationController
    include Pagy::Backend
    layout 'public'

    def new
      @demande_rdv = DemandeRdv.new
    end

    def create
      @demande_rdv = DemandeRdv.new(demande_rdv_params)
      @demande_rdv.statut = "soumis"
      
      # Combiner date et heure si date_rdv n'est pas déjà rempli
      if @demande_rdv.date_rdv.blank?
        date_str = params[:demande_rdv][:date_rdv_date] if params[:demande_rdv]
        time_str = params[:demande_rdv][:date_rdv_time] if params[:demande_rdv]
        
        if date_str.present? && time_str.present?
          @demande_rdv.date_rdv = DateTime.parse("#{date_str} #{time_str}")
        end
      end
      
      
      # Vérifier reCAPTCHA
      unless verify_recaptcha(model: @demande_rdv)
        flash.now[:alert] = "Veuillez compléter le reCAPTCHA pour prouver que vous n'êtes pas un robot"
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream do
            render turbo_stream: turbo_stream.append(
              :flash,
              partial: "public/shared/flash"
            )
          end
        end
        return
      end
 
      if @demande_rdv.save
        # Si le formulaire vient de la cabine d'essayage, créer et associer la demande cabine
        if params[:from_cabine] == "1" && session[:cabine_cart].present?
          @demande_cabine_essayage = @demande_rdv.build_demande_cabine_essayage
          
          # Créer les items avec les produits du panier
          session[:cabine_cart].each do |produit_id|
            @demande_cabine_essayage.demande_cabine_essayage_items.build(produit_id: produit_id)
          end
          
          if @demande_cabine_essayage.save
            # Vider le panier cabine après création réussie
            session[:cabine_cart] = []
            redirect_to cabine_essayage_path, notice: "Votre demande de rendez-vous avec cabine d'essayage a bien été envoyée. Nous vous contacterons bientôt."
          else
            # Si l'association échoue, supprimer la demande RDV créée
            @demande_rdv.destroy
            flash.now[:alert] = "Erreur lors de la création de la demande cabine d'essayage"
            respond_to do |format|
              format.html { render :new, status: :unprocessable_entity }
              format.turbo_stream do
                render turbo_stream: turbo_stream.update(
                  "demande_rdv_form",
                  partial: "public/demande_rdv/form",
                  locals: { demande_rdv: @demande_rdv }
                )
              end
            end
            return
          end
        else
          redirect_to rdv_path, notice: "Votre demande de rendez-vous a bien été envoyée. Nous vous contacterons bientôt."
        end
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream do
            render turbo_stream: turbo_stream.update(
              "demande_rdv_form",
              partial: "public/demande_rdv/form",
              locals: { demande_rdv: @demande_rdv }
            )
          end
        end
      end
    end

    private

    def demande_rdv_params
      params.require(:demande_rdv).permit(
        :prenom, :nom, :email, :telephone, :commentaire, :date_rdv, :type_rdv, :nombre_personnes, :evenement, :date_evenement
      )
    end

  end
end

