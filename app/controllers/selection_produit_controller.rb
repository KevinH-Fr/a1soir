class SelectionProduitController < ApplicationController
  include EnsemblesHelper 
  
  before_action :authenticate_user!
  before_action :authenticate_vendeur_or_admin!
      
  def index

    @commande = Commande.find(session[:commande])
    @type_locvente = @commande.type_locvente

    if params[:article]
      @article = Article.find(params[:article])
      session[:article] = params[:article]
    else 
      session[:article] = nil
    end 

    @titre = @article ? "Sélection sous-article de #{@article.nom_complet}" : "Sélection article" 
    @titre_complet = "#{@titre}" " pour commande #{ @commande.ref_commande }"
    
    @produit = Produit.find(params[:produit]) if params[:produit]
    # search
    @q = Produit.ransack(params[:q])
    @produits = @q.result.includes(:couleur, :taille)

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


    if params[:categorie_produit] == "all"
      type_mono_multi = "multi"
      @categorie_produits = CategorieProduit.pluck(:id)
      @tailles = Taille.all
    else
      type_mono_multi = "mono"
      selected_categorie_produit_id = CategorieProduit.find(params[:categorie_produit]).id
      @categorie_produits = [selected_categorie_produit_id]
      @tailles = Taille.joins(:produits).where(produits: { categorie_produit: selected_categorie_produit_id }).distinct
    end
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update(
           'partial-categorie-selected', partial: 'selection_produit/categorie_selected'
        )
      ]
      end
    end    

  end 

  def display_taille_selected    
    
    if params[:categorie_produit] == "all"
      @categorie_produits = CategorieProduit.pluck(:id)
    elsif params[:categorie_produit].present?
      selected_categorie_produits_ids = CategorieProduit.where(id: params[:categorie_produit]).pluck(:id)
      @categorie_produits = selected_categorie_produits_ids
    end
    
    if params[:taille] == "all"
      @tailles = Taille.all.pluck(:id)
    else
      selected_taille_id = Taille.find(params[:taille]).id
      @tailles = [selected_taille_id]
    end
    @couleurs = Couleur.joins(:produits).where(produits: { categorie_produit: @categorie_produits, taille: @tailles }).distinct

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          'partial-taille-selected', partial: 'selection_produit/taille_selected'
        )
      end
    end    

  end 

  def display_couleur_selected

    @commande = Commande.find(session[:commande])

    if params[:categorie_produit] == "all"
      @categorie_produits = CategorieProduit.pluck(:id)
    elsif params[:categorie_produit].present?  
      selected_categorie_produits_ids = CategorieProduit.where(id: params[:categorie_produit]).pluck(:id)
      @categorie_produits = selected_categorie_produits_ids
    end

    if params[:taille] == "all" 
      @tailles = Taille.pluck(:id)
    elsif params[:taille].present?   
      selected_taille_ids = Taille.where(id: params[:taille]).pluck(:id)
      @tailles = selected_taille_ids
    end
        
    if params[:couleur] == "all"
      @couleurs = Couleur.pluck(:id)
    elsif params[:couleur].present?
      selected_couleur_ids = Couleur.where(id: params[:couleur]).pluck(:id)
      @couleurs = selected_couleur_ids
    end
      
    @produits = Produit.where(categorie_produit: [@categorie_produits, nil])
                       .where(taille: [@tailles, nil])
                       .where(couleur: [@couleurs, nil])

    
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
    
    type_locvente = result[:matching_articles].first&.locvente
    if type_locvente == "location"
      prix =  result[:ensemble].produit.prixlocation
    elsif type_locvente == "vente"
      prix = result[:ensemble].produit.prixvente
    end

    # Create an article in the commande corresponding to the ensemble
    new_article = Article.create(
      produit_id: result[:ensemble].produit.id, 
      commande_id: @commande.id, 
      locvente: type_locvente,
      prix: prix,
      caution: type_locvente == "location" ? result[:ensemble].produit.prixvente : 0,
      total: prix,
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


end
  