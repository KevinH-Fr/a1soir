module CommonPrixProduit
    extend ActiveSupport::Concern
  
    included do
      before_action :set_prix
    end
  
    private
  
    def set_prix
        if params[:produit]
            session[:produit] = params[:produit]
            @prix_location = Produit.find(params[:produit]).prixlocation
            @prix_vente = Produit.find(params[:produit]).prixvente
        else 
            @prix_location = Produit.find(session[:produit]).prixlocation
            @prix_vente =  Produit.find(session[:produit]).prixvente
        end
    end
  end