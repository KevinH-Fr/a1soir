class SelectionProduitController < ApplicationController

  before_action :authenticate_user!
  before_action :authenticate_vendeur_or_admin!
  
    def index
    end
    
    def scanqr
      @commande = Commande.find(session[:commande])
      @article = params[:article] 
      
      if params[:scan]
        @produit_scan = Produit.find(params[:scan]) 
      end

    end 

    private

    def authenticate_vendeur_or_admin!
      unless current_user && (current_user.vendeur? || current_user.admin?)
        redirect_to root_path, alert: "Vous n'avez pas accès à cette page."
      end
    end
end
  