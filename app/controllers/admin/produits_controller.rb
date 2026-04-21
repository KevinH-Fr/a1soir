class Admin::ProduitsController < Admin::ApplicationController

  before_action :authenticate_admin!, only: %i[ destroy edit update toggle_coup_de_coeur move_up_coup_de_coeur move_down_coup_de_coeur apply_promotion remove_promotion ]

  before_action :set_produit, only: %i[ show edit update destroy toggle_active delete_image_attachment delete_video_attachment toggle_coup_de_coeur move_up_coup_de_coeur move_down_coup_de_coeur apply_promotion remove_promotion ]

  def index

    @count_produits = Produit.count
  
    search_params = params.permit(
      :format, :page, :filter_taille, :filter_couleur, :filter_categorie, :filter_type_produit, :filter_statut, :filter_fournisseur, :filter_prix,
      q: [:nom_or_reffrs_or_handle_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_or_fournisseur_nom_cont, :id_eq]
    )
  
    produits = Produit.all
  
    produits = apply_taille_filter(produits, search_params[:filter_taille])
    produits = apply_couleur_filter(produits, search_params[:filter_couleur])
    produits = apply_categorie_filter(produits, search_params[:filter_categorie])
    produits = apply_type_produit_filter(produits, search_params[:filter_type_produit])
    produits = apply_statut_filter(produits, search_params[:filter_statut])
    produits = apply_fournisseur_filter(produits, search_params[:filter_fournisseur])
    produits = apply_prix_filter(produits, search_params[:filter_prix])
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
    raw_term = search_params.dig(:q, :nom_or_reffrs_or_handle_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_or_fournisseur_nom_cont).to_s.strip

    if raw_term.match?(/\A\d+\z/)
      # Terme purement numérique → recherche exacte par ID (id_cont ne fonctionne pas sur integer)
      @q = produits.ransack(id_eq: raw_term)
    elsif raw_term.present?
      keywords = raw_term.split

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
          locals: { produit: @produit, admin_form_row_embedded: true })
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

        format.html do
          admin_push_domain_toast!(flash, :produit, :duplicate_exists)
          redirect_to new_admin_produit_path
        end
      
      elsif @produit.save
        if OnlineSales.available?
          StripeProductService.new(@produit).create_product_and_price
        end
        
        format.html do
          admin_push_domain_toast!(flash, :produit, :created)
          redirect_to admin_produit_url(@produit)
        end
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

        format.html do
          admin_push_domain_toast!(flash, :produit, :duplicate_exists)
          redirect_to admin_produit_path(@produit)
        end
      
      elsif @produit.update(produit_params)
        if OnlineSales.available?
          StripeProductService.new(@produit).update_product_and_price
        end
        
        admin_push_domain_toast!(flash.now, :produit, :updated)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@produit, partial: "admin/produits/produit", locals: {produit: @produit}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :produit, :updated)
          redirect_to produit_url(@produit)
        end
        format.json { render :show, status: :ok, location: @produit }
      else

        format.turbo_stream do
          render turbo_stream: turbo_stream.update(@produit, 
                    partial: 'admin/produits/form', 
                    locals: { produit: @produit, admin_form_row_embedded: true })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @produit.errors, status: :unprocessable_entity }
      end
    end
  end

  def delete_image_attachment
    @media = @produit.images.find(params[:image_id])
    @media.purge
  
    admin_push_domain_toast!(flash, :produit, :image_deleted)
    redirect_to admin_produit_path(@produit)
  end

  def delete_video_attachment
    @produit.video1.purge if @produit.video1.attached?
    admin_push_domain_toast!(flash, :produit, :video_deleted)
    redirect_to admin_produit_path(@produit)
  end

  def destroy
    unless @produit.hard_destroy_allowed?
      respond_with_produit_destroy_blocked
      return
    end

    if @produit.destroy
      respond_to do |format|
        admin_push_domain_toast!(flash.now, :produit, :destroyed)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove(@produit),
            turbo_stream.prepend("flash", partial: "layouts/flash", locals: { flash: flash })
          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :produit, :destroyed)
          redirect_to produits_path
        end
      end
    else
      respond_with_produit_destroy_blocked
    end
  rescue ActiveRecord::DeleteRestrictionError, ActiveRecord::InvalidForeignKey
    respond_with_produit_destroy_blocked
  end

  def toggle_active
    # Archive or restore product
    archive_mode = @produit.actif?
    # Archive => also stop e-shop diffusion
    attrs = archive_mode ? { actif: false, eshop: false } : { actif: true }

    if @produit.update(attrs)
      if archive_mode && OnlineSales.available?
        # Best-effort Stripe deactivation
        StripeProductService.new(@produit).archive_product_and_price
      end

      admin_push_domain_toast!(flash.now, :produit, :updated)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@produit, partial: "admin/produits/produit", locals: { produit: @produit }),
            turbo_stream.prepend("flash", partial: "layouts/flash", locals: { flash: flash })
          ]
        end
        format.html do
          admin_push_domain_toast!(flash, :produit, :updated)
          redirect_back fallback_location: admin_produit_path(@produit)
        end
      end
    else
      admin_push_domain_toast!(flash.now, :produit, :save_error)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash", partial: "layouts/flash", locals: { flash: flash })
        end
        format.html do
          admin_push_domain_toast!(flash, :produit, :save_error)
          redirect_back fallback_location: admin_produit_path(@produit)
        end
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
        copy.stripe_product_id      = nil
        copy.stripe_price_id        = nil
        copy.coup_de_coeur          = false
        copy.coup_de_coeur_position = nil

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
      if OnlineSales.available?
        StripeProductService.new(copy).create_product_and_price 
      end

      admin_push_domain_toast!(flash, :produit, :duplicated)
      redirect_to admin_produit_path(copy)
    else
      admin_push_domain_toast!(flash, :produit, :duplicate_no_base)
      redirect_to admin_produit_path(@produit)
    end
  end

  def toggle_coup_de_coeur
    @produit.coup_de_coeur = !@produit.coup_de_coeur
    
    if @produit.coup_de_coeur
      # Attribuer une position si le produit devient un coup de cœur
      max_position = Produit.where(coup_de_coeur: true).maximum(:coup_de_coeur_position) || -1
      @produit.coup_de_coeur_position = max_position + 1
    else
      # Retirer la position si le produit n'est plus un coup de cœur
      @produit.coup_de_coeur_position = nil
    end
    
    if @produit.save
      if @produit.coup_de_coeur
        admin_push_domain_toast!(flash.now, :produit, :coup_de_coeur_added)
      else
        admin_push_domain_toast!(flash.now, :produit, :coup_de_coeur_removed)
      end

      # Recharger la liste des coups de cœur
      @coups_de_coeur = Produit.coups_de_coeur.includes(:image1_attachment, :categorie_produits)
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "coups_de_coeur_section",
              partial: "admin/textes/coups_de_coeur",
              locals: { coups_de_coeur_list_open: true }
            ),
            turbo_stream.replace(
              "produit_#{@produit.id}_coup_de_coeur",
              partial: "admin/produits/coup_de_coeur_toggle",
              locals: { produit: @produit }
            ),
            turbo_stream.replace("flash", partial: "layouts/flash", locals: { flash: flash, flash_wrap: true })
          ]
        end
        format.html do
          toast_event = @produit.coup_de_coeur ? :coup_de_coeur_added : :coup_de_coeur_removed
          admin_push_domain_toast!(flash, :produit, toast_event)
          redirect_to admin_produits_path
        end
      end
    else
      admin_push_domain_toast!(flash.now, :produit, :save_error)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash", locals: { flash: flash, flash_wrap: true })
        end
        format.html do
          admin_push_domain_toast!(flash, :produit, :save_error)
          redirect_to admin_produits_path
        end
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
        
        admin_push_domain_toast!(flash.now, :produit, :coup_de_coeur_position_updated)
      end
      
      # Recharger la liste des coups de cœur
      @coups_de_coeur = Produit.coups_de_coeur.includes(:image1_attachment, :categorie_produits)
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "coups_de_coeur_section",
              partial: "admin/textes/coups_de_coeur",
              locals: { coups_de_coeur_list_open: true }
            ),
            turbo_stream.replace("flash", partial: "layouts/flash", locals: { flash: flash, flash_wrap: true })
          ]
        end
        format.html do
          admin_push_domain_toast!(flash, :produit, :coup_de_coeur_position_updated) if produit_au_dessus
          redirect_to admin_textes_path(cdc_list: 1)
        end
      end
    else
      admin_push_domain_toast!(flash, :produit, :coup_de_coeur_not_found)
      redirect_to admin_textes_path(cdc_list: 1)
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
        
        admin_push_domain_toast!(flash.now, :produit, :coup_de_coeur_position_updated)
      end
      
      # Recharger la liste des coups de cœur
      @coups_de_coeur = Produit.coups_de_coeur.includes(:image1_attachment, :categorie_produits)
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "coups_de_coeur_section",
              partial: "admin/textes/coups_de_coeur",
              locals: { coups_de_coeur_list_open: true }
            ),
            turbo_stream.replace("flash", partial: "layouts/flash", locals: { flash: flash, flash_wrap: true })
          ]
        end
        format.html do
          admin_push_domain_toast!(flash, :produit, :coup_de_coeur_position_updated) if produit_en_dessous
          redirect_to admin_textes_path(cdc_list: 1)
        end
      end
    else
      admin_push_domain_toast!(flash, :produit, :coup_de_coeur_not_found)
      redirect_to admin_textes_path(cdc_list: 1)
    end
  end

  def apply_promotion
    nouveau_prix = params[:nouveau_prix].to_f
    
    if nouveau_prix <= 0
      admin_push_domain_toast!(flash.now, :produit, :promotion_price_invalid)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash", locals: { flash: flash, flash_wrap: true })
        end
        format.html do
          admin_push_domain_toast!(flash, :produit, :promotion_price_invalid)
          redirect_to admin_produit_path(@produit)
        end
      end
      return
    end

    if @produit.prixvente.nil? || @produit.prixvente <= 0
      admin_push_domain_toast!(flash.now, :produit, :promotion_requires_sale_price)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash", locals: { flash: flash, flash_wrap: true })
        end
        format.html do
          admin_push_domain_toast!(flash, :produit, :promotion_requires_sale_price)
          redirect_to admin_produit_path(@produit)
        end
      end
      return
    end

    @produit.ancien_prixvente = @produit.prixvente
    @produit.prixvente = nouveau_prix

    if @produit.save
      if OnlineSales.available?
        StripeProductService.new(@produit).update_product_and_price
      end
      
      admin_push_domain_toast!(flash.now, :produit, :promotion_applied)
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@produit, partial: "admin/produits/produit", locals: {produit: @produit}),
            turbo_stream.replace("flash", partial: "layouts/flash", locals: { flash: flash, flash_wrap: true })
          ]
        end
        format.html do
          admin_push_domain_toast!(flash, :produit, :promotion_applied)
          redirect_to admin_produit_path(@produit)
        end
      end
    else
      admin_push_domain_toast!(flash.now, :produit, :promotion_apply_error)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash", locals: { flash: flash, flash_wrap: true })
        end
        format.html do
          admin_push_domain_toast!(flash, :produit, :promotion_apply_error)
          redirect_to admin_produit_path(@produit)
        end
      end
    end
  end

  def remove_promotion
    unless @produit.en_promotion?
      admin_push_domain_toast!(flash.now, :produit, :promotion_not_active)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash", locals: { flash: flash, flash_wrap: true })
        end
        format.html do
          admin_push_domain_toast!(flash, :produit, :promotion_not_active)
          redirect_to admin_produit_path(@produit)
        end
      end
      return
    end

    @produit.prixvente = @produit.ancien_prixvente
    @produit.ancien_prixvente = nil

    if @produit.save
      if OnlineSales.available?
        StripeProductService.new(@produit).update_product_and_price
      end
      
      admin_push_domain_toast!(flash.now, :produit, :promotion_removed)
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@produit, partial: "admin/produits/produit", locals: {produit: @produit}),
            turbo_stream.replace("flash", partial: "layouts/flash", locals: { flash: flash, flash_wrap: true })
          ]
        end
        format.html do
          admin_push_domain_toast!(flash, :produit, :promotion_removed)
          redirect_to admin_produit_path(@produit)
        end
      end
    else
      admin_push_domain_toast!(flash.now, :produit, :promotion_remove_error)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash", partial: "layouts/flash", locals: { flash: flash, flash_wrap: true })
        end
        format.html do
          admin_push_domain_toast!(flash, :produit, :promotion_remove_error)
          redirect_to admin_produit_path(@produit)
        end
      end
    end
  end
  
  private

    def respond_with_produit_destroy_blocked
      admin_push_domain_toast!(flash.now, :produit, :destroy_blocked)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash", partial: "layouts/flash", locals: { flash: flash })
        end
        format.html do
          admin_push_domain_toast!(flash, :produit, :destroy_blocked)
          redirect_back fallback_location: admin_produit_path(@produit)
        end
      end
    end

    def set_produit
      @produit = Produit.find(params[:id])
    end

    def produit_params
      params.require(:produit).permit(:nom, :prixvente, :prixlocation, :description, :type_produit_id,
        :caution, :handle, :reffrs, :quantite, :fournisseur_id, :dateachat, :prixachat, :actif,
        :image1, :video1, :couleur_id, :taille_id, :eshop, :poids,
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

  def apply_type_produit_filter(scope, value)
    return scope unless value.present?

    if value == "na"
      scope.where(type_produit_id: nil)
    else
      scope.where(type_produit_id: value)
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

  def apply_prix_filter(scope, value)
    return scope unless value.present?

    if value == "na"
      scope.where('(prixvente IS NULL OR prixvente <= 0) AND (prixlocation IS NULL OR prixlocation <= 0)')
    else
      scope.by_prixmax(value.to_f)
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
