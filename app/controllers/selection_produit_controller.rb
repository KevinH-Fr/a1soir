class SelectionProduitController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:process_qr] # Skip CSRF token check for the process_qr action

  before_action :authenticate_user!
  before_action :authenticate_vendeur_or_admin!
  
    def index
    end
  


    def process_qr
      #  render json: { success: true }
    end
    
    def scanqr
      @commande = params[:commande]
      @article = params[:article] 
      
      @produits_scan = params[:scan]  
      puts "_________________value passed to rails: #{@produits_scan}_______________________________"


    #  redirect_to root_path

    end 

    private

    def authenticate_vendeur_or_admin!
      unless current_user && (current_user.vendeur? || current_user.admin?)
        redirect_to root_path, alert: "Vous n'avez pas accès à cette page."
      end
    end
end
  