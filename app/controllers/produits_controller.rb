class ProduitsController < ApplicationController

  before_action :authenticate_vendeur_or_admin!
  before_action :set_produit, only: %i[ show edit update destroy ]

  def index

    @q = Produit.ransack(params[:q])
    @produits = @q.result(distinct: true)
    
    @categorie_produits = CategorieProduit.all
    @type_produits = TypeProduit.all

    @couleurs = Couleur.all 
    @tailles = Taille.all 
    @fournisseurs = Fournisseur.all 

  end

  def show
    @commandes_liees = Commande.joins(articles: :produit).where(articles: { produit_id: @produit }).distinct
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
          partial: "produits/form", 
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

    respond_to do |format|
      if @produit.save

        #flash.now[:success] = "produit was successfully created"

        #format.turbo_stream do
        #  render turbo_stream: [
        #    turbo_stream.update('new',
        #                        partial: "produits/form",
        #                        locals: { produit: Produit.new }),
  
        #    turbo_stream.prepend('produits',
        #                          partial: "produits/produit",
        #                          locals: { produit: @produit }),
        #    turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
        #  ]
        #end

        format.html { redirect_to produit_url(@produit), notice: I18n.t('notices.successfully_created') }
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

    respond_to do |format|
      if @produit.update(produit_params)

        flash.now[:success] =  I18n.t('notices.successfully_updated')

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@produit, partial: "produits/produit", locals: {produit: @produit}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html { redirect_to produit_url(@produit), notice: "Produit was successfully updated." }
        format.json { render :show, status: :ok, location: @produit }
      else

        format.turbo_stream do
          render turbo_stream: turbo_stream.update(@produit, 
                    partial: 'produits/form', 
                    locals: { produit: @produit })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @produit.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @produit.destroy!

    respond_to do |format|
      format.html { redirect_to produits_url, notice:  I18n.t('notices.successfully_destroyed')}
      format.json { head :no_content }
    end
  end

  def dupliquer
    @produit = Produit.find(params[:id])
  
    if params[:produitbase].present?
      @produitBase = Produit.find(params[:produitbase]) 
  
      # Préparer un nouveau produit qui contient les mêmes données que le courant
      original = @produitBase
      copy = original.dup
      copy.nom = "#{original.nom}_new" # append "new" to the original name
  
      if original.image1.attached?
        copy.image1.attach \
          io: StringIO.new(original.image1.download),
          filename: original.image1.filename,
          content_type: original.image1.content_type
      end
  
      original.images.each do |image|
        if image.attached?
          copy.images.attach \
            io: StringIO.new(image.download),
            filename: image.filename,
            content_type: image.content_type
        end
      end
  
      copy.save!
  
      # Redirect to the newly created product
      redirect_to produit_path(copy),
                  notice: "Duplication du produit effectuée !"
    else
      redirect_to produit_path(@produit),
                  notice: "Aucun produit de base spécifié."
    end
  end
  

  private
    def set_produit
      @produit = Produit.find(params[:id])
    end

    def produit_params
      params.require(:produit).permit(:nom, :prixvente, :prixlocation, :description, :categorie_produit_id, :type_produit_id,
        :caution, :handle, :reffrs, :quantite, :fournisseur_id, :dateachat, :prixachat, 
        :image1, :couleur_id, :taille_id, images: [] )
    end

end
