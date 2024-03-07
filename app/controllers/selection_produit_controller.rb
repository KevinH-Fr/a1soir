class SelectionProduitController < ApplicationController
  include CommonPrixProduit
  include EnsemblesHelper 
  
  before_action :authenticate_user!
  before_action :authenticate_vendeur_or_admin!
      
  def index

    @commande = Commande.find(session[:commande])

    if params[:article]
      @article = Article.find(params[:article])
      session[:article] = params[:article]
    else 
      session[:article] = nil
    end 
    
    @produit = Produit.find(params[:produit]) if params[:produit]

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

  #  @produits = Produit.where(categorie_produit: @categorie_produit, couleur: @couleur)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          'partial-taille-selected', partial: 'selection_produit/taille_selected'
        )
      end
    end    

  end 

  def display_couleur_selected

    @article = session[:article] 

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
  

  def toggle_transformer_ensemble

    @commande = Commande.find(session[:commande])
    result = find_ensemble_matching_type_produits(@commande)

    # Create an article in the commande corresponding to the ensemble
    new_article = Article.create(
      produit_id: result[:ensemble].produit.id, 
      commande_id: @commande.id, 
      #ajouter prix
      #ajouter type locvente
      quantite: 1 )

    # Create sous-articles corresponding to the matching articles
    result[:matching_articles].each do |matching_article|
      Sousarticle.create(
        article_id: new_article.id, 
        produit_id: matching_article.produit.id)
        #passer les prix a zero
    end

    # Delete the initial articles transformed into the ensemble
    result[:matching_articles].destroy_all
    

    redirect_to commande_path(@commande),
      notice: "Transformation en ensemble effectuée"
  end



  private

  def authenticate_vendeur_or_admin!
    unless current_user && (current_user.vendeur? || current_user.admin?)
      redirect_to root_path, alert: "Vous n'avez pas accès à cette page."
    end
  end
end
  