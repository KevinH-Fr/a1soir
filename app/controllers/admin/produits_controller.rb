class Admin::ProduitsController < Admin::ApplicationController

  before_action :authenticate_admin!, only: %i[ edit update ]

  before_action :set_produit, only: %i[ show edit update destroy delete_image_attachment ]

  def index
    @count_produits = Produit.count
  
    search_params = params.permit(
      :format, :page, :filter_taille, :filter_couleur, :filter_categorie, :filter_statut,
      q: [:nom_or_reffrs_or_handle_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_cont]
    )
  
    produits = Produit.all
  
    produits = apply_taille_filter(produits, search_params[:filter_taille])
    produits = apply_couleur_filter(produits, search_params[:filter_couleur])
    produits = apply_categorie_filter(produits, search_params[:filter_categorie])
    produits = apply_statut_filter(produits, search_params[:filter_statut])
    produits = apply_sort(produits, params[:sort])

    @analysis_mode = params[:filter_mode] == "analyse" ? true : false

  
    @q = produits.ransack(search_params[:q])
    produits = @q.result(distinct: true).order(updated_at: :desc)
  
    @pagy, @produits = pagy_countless(produits, items: 2)
  
    @categorie_produits = CategorieProduit.order(:nom)
    @type_produits = TypeProduit.order(:nom)
    @couleurs = Couleur.order(:nom)
    @tailles = Taille.order(:nom)
    @fournisseurs = Fournisseur.all

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
  
  private
    def set_produit
      @produit = Produit.find(params[:id])
    end

    def produit_params
      params.require(:produit).permit(:nom, :prixvente, :prixlocation, :description, :type_produit_id,
        :caution, :handle, :reffrs, :quantite, :fournisseur_id, :dateachat, :prixachat, :actif,
        :image1, :video1, :couleur_id, :taille_id, :eshop, :poids, :stripe_product_id, :stripe_price_id,
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
