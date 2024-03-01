class SelectionProduitController < ApplicationController

  before_action :authenticate_user!
  before_action :authenticate_vendeur_or_admin!
      
    def index
      
      @commande = Commande.find(session[:commande])
      @article = params[:article] 
      
      if params[:produit]
        @produit = Produit.find(params[:produit]) 
        puts "_________________produit slected: #{@produit.id}__________________________"
      end

    end

    def display_qr
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            'partial-container', partial: 'selection_produit/selection_qr'
          )
        end
      end
    end

    def display_manuelle
      @produits = Produit.all 

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            'partial-container', partial: 'selection_produit/selection_manuelle'
          )
        end
      end

    end
    

    private

    def authenticate_vendeur_or_admin!
      unless current_user && (current_user.vendeur? || current_user.admin?)
        redirect_to root_path, alert: "Vous n'avez pas accès à cette page."
      end
    end
end
  