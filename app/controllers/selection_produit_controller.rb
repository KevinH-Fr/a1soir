class SelectionProduitController < ApplicationController

  before_action :authenticate_user!
  before_action :authenticate_vendeur_or_admin!
  
    def index
      @produits = Produit.all 
      
      @commande = Commande.find(session[:commande])
      @article = params[:article] 
      
      if params[:produit]
        @produit = Produit.find(params[:produit]) 
        puts "_________________produit slected: #{@produit.id}__________________________"
      end


    end
    

    private

    def authenticate_vendeur_or_admin!
      unless current_user && (current_user.vendeur? || current_user.admin?)
        redirect_to root_path, alert: "Vous n'avez pas accès à cette page."
      end
    end
end
  