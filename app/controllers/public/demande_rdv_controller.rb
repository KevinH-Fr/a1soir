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
      
      # Combiner date et heure si fournis séparément
      if params[:demande_rdv][:date_rdv_date].present? && params[:demande_rdv][:date_rdv_time].present?
        date_str = params[:demande_rdv][:date_rdv_date]
        time_str = params[:demande_rdv][:date_rdv_time]
        @demande_rdv.date_rdv = DateTime.parse("#{date_str} #{time_str}")
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
        # TODO: Envoi de l'email de confirmation au visiteur
        # DemandeRdvMailer.confirmation_client(@demande_rdv).deliver_later
        # TODO: Notification admin
        # DemandeRdvMailer.notification_admin(@demande_rdv).deliver_later
        redirect_to rdv_path, notice: "Votre demande de rendez-vous a bien été envoyée. Nous vous contacterons bientôt."
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
        :nom, :email, :telephone, :commentaire, :date_rdv, :date_rdv_date, :date_rdv_time
      )
    end

  end
end

