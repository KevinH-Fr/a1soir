class Admin::SelectionProduitController < Admin::ApplicationController
  include EnsemblesHelper 
        
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
          'partial-container', partial: 'admin/selection_produit/selection_qr'
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
          'partial-container', partial: 'admin/selection_produit/selection_manuelle'

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
           'partial-categorie-selected', partial: 'admin/selection_produit/categorie_selected'
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
          'partial-taille-selected', partial: 'admin/selection_produit/taille_selected'
        )
      end
    end    

  end 

  def display_couleur_selected

    @commande = Commande.find(session[:commande])

    if session[:article]
      @article = Article.find(session[:article])
    end 

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
          'partial-couleur-selected', partial: 'admin/selection_produit/couleur_selected'
        )
      end
    end    

  end 
  

  def toggle_transformer_ensemble
    @commande = Commande.find(session[:commande])
  
    # Fetch the results (array of hashes)
    results = find_ensemble_matching_type_produits(@commande)
  
    # Ensure results are present
    if results.blank?
      return redirect_to commande_path(@commande), alert: "Aucun ensemble correspondant trouvé."
    end
  
    # Select the first result (you can adapt this to allow user choice if needed)
    selected_result = results.first
  
    # Extract ensemble and matching articles
    ensemble = selected_result[:ensemble]
    matching_articles = selected_result[:matching_articles]
  
    # Ensure matching articles exist
    if matching_articles.blank?
      return redirect_to commande_path(@commande), alert: "Aucun article correspondant trouvé pour l'ensemble."
    end
  
    # Determine the locvente type and corresponding pricing
    type_locvente = matching_articles.first.locvente
    if type_locvente == "location"
      prix = ensemble.produit.prixlocation
      caution = ensemble.produit.prixvente
    elsif type_locvente == "vente"
      prix = ensemble.produit.prixvente
      caution = 0
    else
      return redirect_to commande_path(@commande), alert: "Type locvente non défini pour la transformation."
    end
  
    # Create a new article for the ensemble
    new_article = Article.create!(
      produit_id: ensemble.produit.id,
      commande_id: @commande.id,
      locvente: type_locvente,
      prix: prix,
      caution: caution,
      total: prix,
      quantite: 1
    )
  
    # Create sous-articles for the matching articles
    matching_articles.each do |matching_article|
      Sousarticle.create!(
        article_id: new_article.id,
        produit_id: matching_article.produit.id,
        commentaires: matching_article.commentaires
      )
    end
  
    # Delete the original articles after transformation
    matching_articles.each(&:destroy)
  
    # Redirect with a success notice
    redirect_to admin_commande_path(@commande),
                notice: "Transformation en ensemble effectuée avec succès."
  end
  
end
  