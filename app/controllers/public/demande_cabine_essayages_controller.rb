module Public
  class DemandeCabineEssayagesController < Public::ApplicationController
    include Pagy::Backend
    layout 'public'

    def new
      @demande_cabine_essayage = DemandeCabineEssayage.new
      
      # Pré-remplir les items avec les produits de la session
      if session[:cabine_cart].present?
        session[:cabine_cart].each do |produit_id|
          @demande_cabine_essayage.demande_cabine_essayage_items.build(produit_id: produit_id)
        end
      end
    end

    def create
      @demande_cabine_essayage = DemandeCabineEssayage.new(demande_cabine_essayage_params)
      @demande_cabine_essayage.statut = "soumis"
      
      # Vérifier reCAPTCHA
      unless verify_recaptcha(model: @demande_cabine_essayage)
        flash.now[:alert] = "Veuillez compléter le reCAPTCHA pour prouver que vous n'êtes pas un robot"
        
        respond_to do |format|
          format.html
          format.turbo_stream do
            render turbo_stream: turbo_stream.append(
              :flash,
              partial: "public/pages/flash"
            )
          end
        end
        return
      end
            
      if @demande_cabine_essayage.save
        # Vider le panier cabine après création réussie
        session[:cabine_cart] = []
        # Envoi de l'email de confirmation au visiteur
        DemandeCabineMailer.confirmation_client(@demande_cabine_essayage).deliver_later
        # Notification admin
        DemandeCabineMailer.notification_admin(@demande_cabine_essayage).deliver_later
        redirect_to cabine_essayage_path, notice: "Votre demande de réservation a bien été envoyée. Nous vous contacterons bientôt."
      end
    end

    private

    def demande_cabine_essayage_params
      params.require(:demande_cabine_essayage).permit(
        :prenom, :nom, :mail, :telephone, :evenement, :date_evenement, :commentaires,
        disponibilites: [],
        demande_cabine_essayage_items_attributes: [:produit_id, :_destroy]
      )
    end

  end
end

