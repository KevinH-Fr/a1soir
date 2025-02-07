class Admin::CategorieProduitsController < Admin::ApplicationController

 # before_action :authenticate_vendeur_or_admin!
  before_action :set_categorie_produit, only: %i[ show edit update destroy ]

  def index

    @count_categorie_produits = CategorieProduit.count

    search_params = params.permit(:format, :page, 
      q:[:nom_cont])
    @q = CategorieProduit.ransack(search_params[:q])
    categorie_produits = @q.result(distinct: true).order(created_at: :desc)
    @pagy, @categorie_produits = pagy_countless(categorie_produits, items: 2)

  end

  def show
  end

  def new
    @categorie_produit = CategorieProduit.new
  end

  def edit
    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@categorie_produit, 
          partial: "admin/categorie_produits/form", 
          locals: {categorie_produit: @categorie_produit})
      end
    end
  end

  def create
    @categorie_produit = CategorieProduit.new(categorie_produit_params)

    respond_to do |format|
      if @categorie_produit.save

        flash.now[:success] =  "Création réussie"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
                                partial: "admin/categorie_produits/form",
                                locals: { categorie_produit: CategorieProduit.new }),
  
            turbo_stream.prepend('categorie_produits',
                                  partial: "admin/categorie_produits/categorie_produit",
                                  locals: { categorie_produit: @categorie_produit }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end
          

        format.html { redirect_to categorie_produit_url(@categorie_produit), notice: "Categorie produit was successfully created." }
        format.json { render :show, status: :created, location: @categorie_produit }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @categorie_produit.errors, status: :unprocessable_entity }
      end
    end

  end

  def update
    respond_to do |format|
      if @categorie_produit.update(categorie_produit_params)
        flash.now[:success] =  "Mise à jour réussie"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@categorie_produit, 
                    partial: 'admin/categorie_produits/categorie_produit', 
                    locals: { categorie_produit: @categorie_produit }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html { redirect_to categorie_produit_url(@categorie_produit), notice: "categorie_produit was successfully updated." }
        format.json { render :show, status: :ok, location: @categorie_produit }
      else

        format.turbo_stream do
          render turbo_stream: turbo_stream.update(@categorie_produit, 
                    partial: 'admin/categorie_produits/form', 
                    locals: { categorie_produit: @categorie_produit })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @categorie_produit.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @categorie_produit.destroy!

    respond_to do |format|
      format.html { redirect_to categorie_produits_url, notice:  "Suppression réussie"  }
      format.json { head :no_content }
    end
  end

  private
    def set_categorie_produit
      @categorie_produit = CategorieProduit.find(params[:id])
    end

    def categorie_produit_params
      params.require(:categorie_produit).permit(:nom, :service, :texte_annonce, :label)
    end


end
