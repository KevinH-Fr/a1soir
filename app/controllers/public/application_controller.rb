module Public
   class ApplicationController < ActionController::Base
      layout "public"

      include Pagy::Backend

      before_action :initialize_session
      before_action :load_cart
      before_action :initialize_cabine_session
      before_action :load_cabine_cart
    
      # before_action :authenticate_user!

      # tempo pour construire en cachant
     # before_action :authenticate_vendeur_or_admin! 

      private

      def initialize_session
         session[:cart] ||= [] # empty cart = empty array
      end
   
      def load_cart
         @cart = Produit.find(session[:cart])
      end

      def initialize_cabine_session
         session[:cabine_cart] ||= [] # empty cabine cart = empty array
      end
   
      def load_cabine_cart
         @cabine_cart = Produit.where(id: session[:cabine_cart])
      end
      
      # def authenticate_vendeur_or_admin!
      #    unless current_admin_user && (current_admin_user.vendeur? || current_admin_user.admin?)
      #       render "admin/home_admin/demande_connexion", alert: "Vous n'avez pas accès à cette page. Veuillez vous connecter."
      #    end
      # end

   end 
   
end