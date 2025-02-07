class Admin::ApplicationController < ActionController::Base
 
   before_action :authenticate_user!  # Ensure the user is logged in
 #  before_action :ensure_admin!       # Ensure the logged-in user is an admin
 
   layout 'admin'  # Use a custom layout for the admin interface
 
   include Pagy::Backend

   private
 
   def ensure_admin!
      unless current_user&.role == "admin"  # Check if the current user is an admin
         #redirect_to root_path, alert: 'Access denied!'  # Redirect if not an admin
         render "admin/home_admin/demande_connexion", alert: "Vous n'avez pas accès à cette page. Veuillez vous connecter."

      end
   end

   # def authenticate_vendeur_or_admin!
   #    unless current_admin_user && (current_admin_user.vendeur? || current_admin_user.admin?)
   #       render "admin/home_admin/demande_connexion", alert: "Vous n'avez pas accès à cette page. Veuillez vous connecter."
   #    end
   # end

   # def authenticate_admin!
   #    unless current_admin_user && current_admin_user.admin?
   #      render "admin/home_admin/demande_connexion", alert: "Vous n'avez pas accès à cette page. Veuillez vous connecter."
   #    end
   # end
    
end
