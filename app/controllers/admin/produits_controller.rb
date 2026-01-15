class Admin::ProduitsController < Admin::ApplicationController

  before_action :authenticate_admin!, only: %i[ edit update toggle_coup_de_coeur move_up_coup_de_coeur move_down_coup_de_coeur apply_promotion remove_promotion ]

  before_action :set_produit, only: %i[ show edit update destroy delete_image_attachment delete_video_attachment toggle_coup_de_coeur move_up_coup_de_coeur move_down_coup_de_coeur apply_promotion remove_promotion ]

  def index
    Rails.logger.debug do
      "Admin::ProduitsController#index params q=#{params[:q].inspect} filters=#{params.slice(:filter_taille, :filter_couleur, :filter_categorie, :filter_statut, :filter_fournisseur, :filter_mode, :sort)}"
    end

    @count_produits = Produit.count
  
    search_params = params.permit(
      :format, :page, :filter_taille, :filter_couleur, :filter_categorie, :filter_statut, :filter_fournisseur,
      q: [:nom_or_reffrs_or_handle_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_or_fournisseur_nom_cont]
    )
  
    produits = Produit.all
  
    produits = apply_taille_filter(produits, search_params[:filter_taille])
    produits = apply_couleur_filter(produits, search_params[:filter_couleur])
    produits = apply_categorie_filter(produits, search_params[:filter_categorie])
    produits = apply_statut_filter(produits, search_params[:filter_statut])
    produits = apply_fournisseur_filter(produits, search_params[:filter_fournisseur])
    produits = apply_sort(produits, params[:sort])
  
    @analysis_mode = params[:filter_mode] == "analyse"
  
    if @analysis_mode
      @produits_analyse_count = produits.count

      @stock_disponible_total = produits.where(today_availability: true).sum(:quantite)
      
      # Chargement des tailles et couleurs distinctes utilisées
      taille_ids = produits.where.not(taille_id: nil).distinct.pluck(:taille_id)
      couleur_ids = produits.where.not(couleur_id: nil).distinct.pluck(:couleur_id)

      @tailles_utilisees = Taille.where(id: taille_ids).order(:nom)
      @couleurs_utilisees = Couleur.where(id: couleur_ids).order(:nom)
    
      @tailles_count = @tailles_utilisees.size
      @couleurs_count = @couleurs_utilisees.size

    end
  
    # Traitement de la recherche multi-mots
    if search_params[:q].present? &&
       search_params[:q][:nom_or_reffrs_or_handle_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_or_fournisseur_nom_cont].present?
  
      keywords = search_params[:q][:nom_or_reffrs_or_handle_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_or_fournisseur_nom_cont]
                 .to_s.strip.split
  
      groupings = keywords.map do |word|
        {
          nom_or_reffrs_or_handle_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_or_fournisseur_nom_cont: word
        }
      end
  
      @q = produits.ransack(combinator: 'and', groupings: groupings)
    else
      @q = produits.ransack(search_params[:q])
    end
  
    produits = @q.result(distinct: true).order(updated_at: :desc)
  
    @pagy, @produits = pagy_countless(produits, items: 2)
  
    @categorie_produits = CategorieProduit.order(:nom)
    @type_produits = TypeProduit.order(:nom)
    @couleurs = Couleur.order(:nom)
    @tailles = Taille.order(:nom)
    @fournisseurs = Fournisseur.order(:nom)
  end
  
  

  def show
    @commandes_liees = Commande
    .includes([:client])
    .joins(:articles)
    .left_joins(articles: :sousarticles)
    .where(articles: { produit_id: @produit.id })
    .or(Commande.where(sousarticles: { produit_id: @produit.id }))
    .order(created_at: :desc)
    .distinct
  end

  def new
    @produit = Produit.new
    @categorie_produits = CategorieProduit.all
    @type_produits = TypeProduit.all

    @couleurs = Couleur.all 
    @tailles = Taille.all 
    @fournisseurs = Fournisseur.all 

  end

  def edit
    @categorie_produits = CategorieProduit.all
    @type_produits = TypeProduit.all

    @couleurs = Couleur.all 
    @tailles = Taille.all 
    @fournisseurs = Fournisseur.all 

    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@produit, 
          partial: "admin/produits/form", 
          locals: {produit: @produit})
      end
    end
  end

  def create
    @produit = Produit.new(produit_params)

    same_existing_produit = Produit.find_by(
      reffrs: @produit.reffrs,
      nom: @produit.nom,
      taille: @produit.taille
    )
    
    @categorie_produits = CategorieProduit.all
    @type_produits = TypeProduit.all

    @couleurs = Couleur.all 
    @tailles = Taille.all 
    @fournisseurs = Fournisseur.all 

    if params[:produit][:images].present?
      params[:produit][:images].each do |image|
        @produit.images.attach(image)
      end
    end
    
    respond_to do |format|

      if same_existing_produit

        format.html { redirect_to new_admin_produit_path, notice: "Un produit avec la même référence existe déjà"}
      
      elsif @produit.save
        if ENV["ONLINE_SALES_AVAILABLE"] == "true"
          StripeProductService.new(@produit).create_product_and_price
        end
        
        format.html { redirect_to admin_produit_url(@produit), notice: "Création réussie" }
        format.json { render :show, status: :created, location: @produit }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @produit.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @categorie_produits = CategorieProduit.all
    @type_produits = TypeProduit.all

    @couleurs = Couleur.all 
    @tailles = Taille.all 
    @fournisseurs = Fournisseur.all 

    same_existing_produit = Produit.where.not(id: @produit.id).find_by(
      reffrs: params[:produit][:reffrs],
      nom: params[:produit][:nom],
      taille: params[:produit][:taille_id]
    )
    

    #puts " __________________ data same existing produit : #{params[:produit][:taille_id]} "

    # Retain existing medias if the field is left empty
    if params[:produit][:images].present?
      params[:produit][:images].each do |image|
        @produit.images.attach(image)
      end
    end
    
    respond_to do |format|

      if same_existing_produit

        format.html { redirect_to admin_produit_path(@produit), notice: "Un produit avec la même référence existe déjà"}
      
      elsif @produit.update(produit_params)
        if ENV["ONLINE_SALES_AVAILABLE"] == "true"
          StripeProductService.new(@produit).update_product_and_price
        end
        
        flash.now[:success] =  "Mise à jour réussie"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@produit, partial: "admin/produits/produit", locals: {produit: @produit}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html { redirect_to produit_url(@produit), notice: "Produit was successfully updated." }
        format.json { render :show, status: :ok, location: @produit }
      else

        format.turbo_stream do
          render turbo_stream: turbo_stream.update(@produit, 
                    partial: 'admin/produits/form', 
                    locals: { produit: @produit })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @produit.errors, status: :unprocessable_entity }
      end
    end
  end

  def delete_image_attachment
    @media = @produit.images.find(params[:image_id])
    @media.purge
  
    redirect_to admin_produit_path(@produit), notice: "Media has been deleted successfully."
  end

  def delete_video_attachment
    @produit.video1.purge if @produit.video1.attached?
    redirect_to admin_produit_path(@produit), notice: "Vidéo supprimée avec succès."
  end

  def destroy
    @produit.destroy

    if @produit.destroy
      respond_to do |format|

        flash.now[:success] = "Destruction réussie"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove(@produit),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html { redirect_to produits_path, notice:  "Suppression réussie" }
      end
    end

  end


  def dupliquer
    @produit = Produit.find(params[:id])
  
    if params[:produitbase].present?
      @produitBase = Produit.find(params[:produitbase])
  
      copy = nil
  
      Produit.transaction do
        original = @produitBase
        copy = original.dup
        copy.nom = "#{original.nom}_new"
  
        # Copy associated categories (if any)
        copy.categorie_produits = original.categorie_produits
  
        copy.save! # Save the copy inside the transaction
      end
  
      # Attach existing blobs directly
      if @produitBase.image1.attached?
        copy.image1.attach(@produitBase.image1.blob)
      end

      @produitBase.images.each do |image|
        copy.images.attach(image.blob)
      end
  
      # Call Stripe Service outside the transaction
      if ENV["ONLINE_SALES_AVAILABLE"] == "true"
        StripeProductService.new(copy).create_product_and_price 
      end

      redirect_to admin_produit_path(copy), notice: "Duplication du produit effectuée !"
    else
      redirect_to admin_produit_path(@produit), notice: "Aucun produit de base spécifié."
    end
  end

  def toggle_coup_de_coeur
    @produit.coup_de_coeur = !@produit.coup_de_coeur
    
    if @produit.coup_de_coeur
      # Attribuer une position si le produit devient un coup de cœur
      max_position = Produit.where(coup_de_coeur: true).maximum(:coup_de_coeur_position) || -1
      @produit.coup_de_coeur_position = max_position + 1
      flash.now[:notice] = "Produit ajouté aux coups de cœur"
    else
      # Retirer la position si le produit n'est plus un coup de cœur
      @produit.coup_de_coeur_position = nil
      flash.now[:notice] = "Produit retiré des coups de cœur"
    end
    
    if @produit.save
      # Recharger la liste des coups de cœur
      @coups_de_coeur = Produit.coups_de_coeur.includes(:image1_attachment, :categorie_produits)
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "coups_de_coeur_section",
              partial: "admin/textes/coups_de_coeur"
            ),
            turbo_stream.replace(
              "produit_#{@produit.id}_coup_de_coeur",
              partial: "admin/produits/coup_de_coeur_toggle",
              locals: { produit: @produit }
            ),
            turbo_stream.replace("flash", partial: "layouts/flash")
          ]
        end
        format.html { redirect_to admin_produits_path, notice: flash.now[:notice] }
      end
    else
      flash.now[:alert] = "Erreur lors de la mise à jour"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash")
        end
        format.html { redirect_to admin_produits_path, alert: "Erreur lors de la mise à jour" }
      end
    end
  end

  def move_up_coup_de_coeur
    if @produit.coup_de_coeur
      # Trouver le produit avec la position juste au-dessus
      produit_au_dessus = Produit.where(coup_de_coeur: true)
                                  .where("coup_de_coeur_position < ?", @produit.coup_de_coeur_position)
                                  .order(coup_de_coeur_position: :desc)
                                  .first
      
      if produit_au_dessus
        # Échanger les positions
        position_temp = @produit.coup_de_coeur_position
        @produit.update_column(:coup_de_coeur_position, produit_au_dessus.coup_de_coeur_position)
        produit_au_dessus.update_column(:coup_de_coeur_position, position_temp)
        
        flash.now[:notice] = "Position mise à jour"
      end
      
      # Recharger la liste des coups de cœur
      @coups_de_coeur = Produit.coups_de_coeur.includes(:image1_attachment, :categorie_produits)
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("coups_de_coeur_section", partial: "admin/textes/coups_de_coeur"),
            turbo_stream.replace("flash", partial: "layouts/flash")
          ]
        end
        format.html { redirect_to admin_textes_path }
      end
    else
      redirect_to admin_textes_path, alert: "Produit non trouvé"
    end
  end

  def move_down_coup_de_coeur
    if @produit.coup_de_coeur
      # Trouver le produit avec la position juste en dessous
      produit_en_dessous = Produit.where(coup_de_coeur: true)
                                   .where("coup_de_coeur_position > ?", @produit.coup_de_coeur_position)
                                   .order(coup_de_coeur_position: :asc)
                                   .first
      
      if produit_en_dessous
        # Échanger les positions
        position_temp = @produit.coup_de_coeur_position
        @produit.update_column(:coup_de_coeur_position, produit_en_dessous.coup_de_coeur_position)
        produit_en_dessous.update_column(:coup_de_coeur_position, position_temp)
        
        flash.now[:notice] = "Position mise à jour"
      end
      
      # Recharger la liste des coups de cœur
      @coups_de_coeur = Produit.coups_de_coeur.includes(:image1_attachment, :categorie_produits)
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("coups_de_coeur_section", partial: "admin/textes/coups_de_coeur"),
            turbo_stream.replace("flash", partial: "layouts/flash")
          ]
        end
        format.html { redirect_to admin_textes_path }
      end
    else
      redirect_to admin_textes_path, alert: "Produit non trouvé"
    end
  end

  def apply_promotion
    nouveau_prix = params[:nouveau_prix].to_f
    
    if nouveau_prix <= 0
      flash.now[:alert] = "Le nouveau prix doit être supérieur à 0"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash", locals: { flash: flash })
        end
        format.html { redirect_to admin_produit_path(@produit), alert: "Le nouveau prix doit être supérieur à 0" }
      end
      return
    end

    if @produit.prixvente.nil? || @produit.prixvente <= 0
      flash.now[:alert] = "Le produit doit avoir un prix de vente pour appliquer une promotion"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash", locals: { flash: flash })
        end
        format.html { redirect_to admin_produit_path(@produit), alert: "Le produit doit avoir un prix de vente pour appliquer une promotion" }
      end
      return
    end

    @produit.ancien_prixvente = @produit.prixvente
    @produit.prixvente = nouveau_prix

    if @produit.save
      if ENV["ONLINE_SALES_AVAILABLE"] == "true"
        StripeProductService.new(@produit).update_product_and_price
      end
      
      flash.now[:success] = "Promotion appliquée avec succès"
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@produit, partial: "admin/produits/produit", locals: {produit: @produit}),
            turbo_stream.replace("flash", partial: "layouts/flash", locals: { flash: flash })
          ]
        end
        format.html { redirect_to admin_produit_path(@produit), notice: "Promotion appliquée avec succès" }
      end
    else
      flash.now[:alert] = "Erreur lors de l'application de la promotion"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash", locals: { flash: flash })
        end
        format.html { redirect_to admin_produit_path(@produit), alert: "Erreur lors de l'application de la promotion" }
      end
    end
  end

  def remove_promotion
    unless @produit.en_promotion?
      flash.now[:alert] = "Ce produit n'est pas en promotion"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash", locals: { flash: flash })
        end
        format.html { redirect_to admin_produit_path(@produit), alert: "Ce produit n'est pas en promotion" }
      end
      return
    end

    @produit.prixvente = @produit.ancien_prixvente
    @produit.ancien_prixvente = nil

    if @produit.save
      if ENV["ONLINE_SALES_AVAILABLE"] == "true"
        StripeProductService.new(@produit).update_product_and_price
      end
      
      flash.now[:success] = "Promotion retirée avec succès"
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@produit, partial: "admin/produits/produit", locals: {produit: @produit}),
            turbo_stream.replace("flash", partial: "layouts/flash", locals: { flash: flash })
          ]
        end
        format.html { redirect_to admin_produit_path(@produit), notice: "Promotion retirée avec succès" }
      end
    else
      flash.now[:alert] = "Erreur lors du retrait de la promotion"
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash", locals: { flash: flash })
        end
        format.html { redirect_to admin_produit_path(@produit), alert: "Erreur lors du retrait de la promotion" }
      end
    end
  end
  
  private
    def set_produit
      @produit = Produit.find(params[:id])
    end

    def produit_params
      params.require(:produit).permit(:nom, :prixvente, :prixlocation, :description, :type_produit_id,
        :caution, :handle, :reffrs, :quantite, :fournisseur_id, :dateachat, :prixachat, :actif,
        :image1, :video1, :couleur_id, :taille_id, :eshop, :poids, :stripe_product_id, :stripe_price_id,
        :coup_de_coeur, :coup_de_coeur_position, :ancien_prixvente,
        categorie_produit_ids: [])
    end


  def apply_taille_filter(scope, value)
    return scope unless value.present?

    if value == "na"
      scope.where(taille_id: nil)
    else
      scope.by_taille(value)
    end
  end

  def apply_couleur_filter(scope, value)
    return scope unless value.present?

    if value == "na"
      scope.where(couleur_id: nil)
    else
      scope.by_couleur(value)
    end
  end

  def apply_categorie_filter(scope, value)
    return scope unless value.present?

    if value == "na"
      scope.left_outer_joins(:categorie_produits).where(categorie_produits: { id: nil })
    else
      scope.by_categorie(CategorieProduit.find(value))
    end
  end

  def apply_statut_filter(scope, value)
    return scope unless value.present?

    case value
    when "na"
      scope.where(actif: nil)
    when "true"
      scope.actif
    when "false"
      scope.inactif
    else
      scope
    end
  end

  def apply_fournisseur_filter(scope, value)
    return scope unless value.present?

    if value == "na"
      scope.where(fournisseur_id: nil)
    else
      scope.by_fournisseur(Fournisseur.find(value))
    end
  end

  def apply_sort(scope, sort_param)
    case sort_param
    when "name_asc"         then scope.order(nom: :asc)
    when "name_desc"        then scope.order(nom: :desc)
    when "created_at_asc"   then scope.order(created_at: :asc)
    when "created_at_desc"  then scope.order(created_at: :desc)
    when "prixlocation_asc" then scope.order(prixlocation: :asc)
    when "prixlocation_desc" then scope.order(prixlocation: :desc)
    when "prixvente_asc"    then scope.order(prixvente: :asc)
    when "prixvente_desc"   then scope.order(prixvente: :desc)
    else scope
    end
  end


end
