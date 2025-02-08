class Admin::ApplicationController < ActionController::Base
 
   before_action :authenticate_vendeur_or_admin! 
   layout 'admin' 
 
   include Pagy::Backend

   private

   def authenticate_vendeur_or_admin!
      unless current_admin_user && (current_admin_user.vendeur? || current_admin_user.admin?)
         render "admin/home_admin/demande_connexion", alert: "Vous n'avez pas accès à cette page. Veuillez vous connecter."
      end
   end

   def authenticate_admin!
      unless current_admin_user && current_admin_user.admin?
         render "admin/home_admin/demande_connexion", alert: "Vous n'avez pas accès à cette page. Veuillez vous connecter."
      end
   end
    
end
