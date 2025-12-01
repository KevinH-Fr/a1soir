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
      
      # Normaliser type_rdv en minuscule
      if @demande_rdv.type_rdv.present?
        @demande_rdv.type_rdv = @demande_rdv.type_rdv.downcase
      end
      
      # Vérifier reCAPTCHA
      unless verify_recaptcha(model: @demande_rdv)
        flash.now[:alert] = "Veuillez compléter le reCAPTCHA pour prouver que vous n'êtes pas un robot"
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.append(:flash, partial: "public/shared/flash"),
              turbo_stream.update("demande_rdv_form", partial: "public/demande_rdv/form", locals: { demande_rdv: @demande_rdv })
            ]
          end
        end
        return
      end
 
      if @demande_rdv.save
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
        :prenom, :nom, :email, :telephone, :commentaire, :date_rdv, :type_rdv, :nombre_personnes
      )
    end

  end
end

