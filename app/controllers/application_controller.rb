class ApplicationController < ActionController::Base

    protected

    def authenticate_vendeur_or_admin!
      unless current_user && (current_user.vendeur? || current_user.admin?)
        render "home_admin/demande_connexion", alert: "Vous n'avez pas accès à cette page. Veuillez vous connecter."
      end
    end
    
end
