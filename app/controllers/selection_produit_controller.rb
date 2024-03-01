class SelectionProduitController < ApplicationController

  before_action :authenticate_user!
  before_action :authenticate_vendeur_or_admin!
      
  def index
    @commande = Commande.find(session[:commande])
    @article = params[:article] 
    
    if params[:produit]
      @produit = Produit.find(params[:produit]) 
    end

    # search
    @q = Produit.ransack(params[:q])
    @produits = @q.result


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

    @categorie_produits = CategorieProduit.all
  
    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          'partial-container', partial: 'selection_produit/selection_manuelle'
        )
      end
    end
  end

  def display_categorie_selected
    @categorie_produit = CategorieProduit.find(params[:categorie_produit])

    @tailles = Taille.all 


    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          'partial-categorie-selected', partial: 'selection_produit/categorie_selected'
        )
      end
    end    

  end 

  def display_taille_selected

    @couleurs = Couleur.all 
    @categorie_produit = CategorieProduit.find(params[:categorie_produit])
    @taille = Taille.find(params[:taille])

    @produits = Produit.where(categorie_produit: @categorie_produit, couleur: @couleur)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          'partial-taille-selected', partial: 'selection_produit/taille_selected'
        )
      end
    end    

  end 

  def display_couleur_selected

    @categorie_produit = CategorieProduit.find(params[:categorie_produit])
    @couleur = Couleur.find(params[:couleur])
    @produits = Produit.where(categorie_produit: @categorie_produit, couleur: @couleur)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          'partial-couleur-selected', partial: 'selection_produit/couleur_selected'
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
  