class Admin::ProduitsController < Admin::ApplicationController

  #before_action :authenticate_vendeur_or_admin!
  before_action :set_produit, only: %i[ show edit update destroy delete_image_attachment ]

  def index
    @count_produits = Produit.count

    search_params = params.permit(:format, :page, 
       q:[:nom_or_reffrs_or_handle_or_categorie_produit_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_cont])
       # without integer to prevent error on pg search, if needed add custom function to be able to search also on price
       # or_prixvente_or_prixlocation 
       
    @q = Produit.ransack(search_params[:q])
    produits = @q.result(distinct: true).order(nom: :asc)
    @pagy, @produits = pagy_countless(produits, items: 2)


    @categorie_produits = CategorieProduit.all
    @type_produits = TypeProduit.all

    @couleurs = Couleur.all 
    @tailles = Taille.all 
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
    @categorie_produits = CategorieProduit.all
    @type_produits = TypeProduit.all

    @couleurs = Couleur.all 
    @tailles = Taille.all 
    @fournisseurs = Fournisseur.all 

    respond_to do |format|
      if @produit.save
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

    # Retain existing medias if the field is left empty
    if params[:produit][:images].present?
      params[:produit][:images].each do |image|
        @produit.images.attach(image)
      end
    end
    
    respond_to do |format|
      if @produit.update(produit_params)

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
  
      Produit.transaction do
        original = @produitBase
        copy = original.dup
        copy.nom = "#{original.nom}_new"
  
        if original.image1.attached?
          copy.image1.attach \
            io: StringIO.new(original.image1.download),
            filename: original.image1.filename,
            content_type: original.image1.content_type
        end
  
        original.images.each do |image|
          #if image.attached?
            copy.images.attach \
              io: StringIO.new(image.download),
              filename: image.filename,
              content_type: image.content_type
          #end
        end
  
        copy.save!
   
        redirect_to admin_produit_path(copy), notice: "Duplication du produit effectuée !"
      end
  
    else
      redirect_to admin_produit_path(@produit), notice: "Aucun produit de base spécifié."
    end
  end
  


  private
    def set_produit
      @produit = Produit.find(params[:id])
    end

    def produit_params
      params.require(:produit).permit(:nom, :prixvente, :prixlocation, :description, :categorie_produit_id, :type_produit_id,
        :caution, :handle, :reffrs, :quantite, :fournisseur_id, :dateachat, :prixachat, :actif,
        :image1, :couleur_id, :taille_id, :eshop)
    end

end
