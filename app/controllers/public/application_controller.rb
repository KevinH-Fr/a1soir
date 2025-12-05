module Public
   class ApplicationController < ActionController::Base
      layout "public"

      include Pagy::Backend

      before_action :initialize_session
      before_action :load_cart
      before_action :initialize_cabine_session
      before_action :load_cabine_cart
      before_action :load_footer_textes
      # Protect every action in the public (shop) namespace with HTTP Basic when enabled.
      before_action :authenticate_shop, if: :shop_basic_enabled?
    
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
        # Initialiser uniquement - pas de normalisation ici pour éviter les conflits
        session[:cabine_cart] ||= []
      end
   
      def load_cabine_cart
        # Normaliser UNE SEULE FOIS ici à la lecture
        if session[:cabine_cart].present? && session[:cabine_cart].any?
          clean_ids = session[:cabine_cart].map(&:to_i).compact.uniq
          # Mettre à jour la session avec les IDs propres si nécessaire
          session[:cabine_cart] = clean_ids unless clean_ids == session[:cabine_cart]
        end
        
        ids = session[:cabine_cart] || []
        @cabine_cart = ids.any? ? Produit.where(id: ids) : Produit.none
      end

      def load_footer_textes
        if Texte.last.present?
          @footer_texte_adresse = Texte.last.adresse
          @footer_texte_horaire = Texte.last.horaire
          @footer_texte_contact = Texte.last.contact
        end
      end
      
      # def authenticate_vendeur_or_admin!
      #    unless current_admin_user && (current_admin_user.vendeur? || current_admin_user.admin?)
      #       render "admin/home_admin/demande_connexion", alert: "Vous n'avez pas accès à cette page. Veuillez vous connecter."
      #    end
      # end

      # Evaluate the flag to know whether shop protection must run in the current environment.
      def shop_basic_enabled?
        value = ENV.fetch("SHOP_PASSWORD_ENABLED", "true")
        ActiveModel::Type::Boolean.new.cast(value)
      end

      # Prompt for HTTP Basic credentials and validate the username/password against ENV or credentials.
      def authenticate_shop
        username = ENV["SHOP_USERNAME"]
        password = ENV["SHOP_PASSWORD"]
        
        authenticate_or_request_with_http_basic("Shop") do |login, pass|
          secure_compare(login, username) && secure_compare(pass, password)
        end
      end

      # Compare strings in constant time to avoid timing attacks when checking credentials.
      def secure_compare(a, b)
        return false if a.blank? || b.blank? || a.bytesize != b.bytesize

        ActiveSupport::SecurityUtils.secure_compare(a, b)
      end

   end 
   
end