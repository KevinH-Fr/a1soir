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
      
      # Debug
      #Rails.logger.debug "Demande params: #{demande_cabine_essayage_params.inspect}"
      #Rails.logger.debug "Items after build: #{@demande_cabine_essayage.demande_cabine_essayage_items.inspect}"
      
      if @demande_cabine_essayage.save
        # Vider le panier cabine après création réussie
        session[:cabine_cart] = []
        # Envoi de l'email de confirmation au visiteur
        DemandeCabineMailer.confirmation_client(@demande_cabine_essayage).deliver_later
        # Notification admin
        DemandeCabineMailer.notification_admin(@demande_cabine_essayage).deliver_later
        redirect_to cabine_essayage_path, notice: "Votre demande de réservation a bien été envoyée. Nous vous contacterons bientôt."
      else
        Rails.logger.debug "Errors: #{@demande_cabine_essayage.errors.full_messages.inspect}"
        render :new, status: :unprocessable_entity
      end
    end

    private

    def demande_cabine_essayage_params
      params.require(:demande_cabine_essayage).permit(
        :prenom, :nom, :mail, :telephone, :evenement, :date_evenement, :commentaires,
        demande_cabine_essayage_items_attributes: [:produit_id, :_destroy]
      )
    end

  end
end

