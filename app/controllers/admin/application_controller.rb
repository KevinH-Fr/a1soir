class Admin::ApplicationController < ActionController::Base
  # La locale publique (/en) et les mailers restent sur le thread. L'admin est toujours en français.
  prepend_before_action { I18n.locale = :fr }

  before_action :authenticate_vendeur_or_admin! 
   layout 'admin' 
 
   include Pagy::Backend
   include AdminFlashToast

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
