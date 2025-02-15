module Public
   class ApplicationController < ActionController::Base
      layout "public"
      # before_action :authenticate_user!

      # tempo pour construire en cachant
     # before_action :authenticate_vendeur_or_admin! 

      private

      # def authenticate_vendeur_or_admin!
      #    unless current_admin_user && (current_admin_user.vendeur? || current_admin_user.admin?)
      #       render "admin/home_admin/demande_connexion", alert: "Vous n'avez pas accès à cette page. Veuillez vous connecter."
      #    end
      # end

   end 
   
end