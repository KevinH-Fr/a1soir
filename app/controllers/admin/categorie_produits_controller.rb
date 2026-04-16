class Admin::CategorieProduitsController < Admin::ApplicationController

  before_action :authenticate_admin!
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
    produits_scope = @categorie_produit.produits.order(updated_at: :desc)
    @pagy, @produits = pagy_countless(produits_scope, items: 4)
  end

  def new
    @categorie_produit = CategorieProduit.new
  end

  def edit
    respond_to do |format|
      format.html 
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          @categorie_produit,
          partial: "admin/categorie_produits/form",
          locals: { categorie_produit: @categorie_produit, admin_form_row_embedded: true }
        )
      end
    end
  end

  def create
    @categorie_produit = CategorieProduit.new(categorie_produit_params)

    respond_to do |format|
      if @categorie_produit.save

        admin_push_domain_toast!(flash.now, :categorie_produit, :created)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("new",
                                partial: "admin/categorie_produits/form",
                                locals: { categorie_produit: CategorieProduit.new, index_collapse: true }),
  
            turbo_stream.prepend('categorie_produits',
                                  partial: "admin/categorie_produits/categorie_produit",
                                  locals: { categorie_produit: @categorie_produit }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end
          

        format.html do
          admin_push_domain_toast!(flash, :categorie_produit, :created)
          redirect_to categorie_produit_url(@categorie_produit)
        end
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
        admin_push_domain_toast!(flash.now, :categorie_produit, :updated)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@categorie_produit, 
                    partial: 'admin/categorie_produits/categorie_produit', 
                    locals: { categorie_produit: @categorie_produit }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :categorie_produit, :updated)
          redirect_to categorie_produit_url(@categorie_produit)
        end
        format.json { render :show, status: :ok, location: @categorie_produit }
      else

        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            @categorie_produit,
            partial: "admin/categorie_produits/form",
            locals: { categorie_produit: @categorie_produit, admin_form_row_embedded: true }
          )
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @categorie_produit.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    unless @categorie_produit.hard_destroy_allowed?
      respond_with_categorie_produit_destroy_blocked
      return
    end

    if @categorie_produit.destroy
      respond_to do |format|
        admin_push_domain_toast!(flash.now, :categorie_produit, :destroyed)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove(@categorie_produit),
            turbo_stream.prepend("flash", partial: "layouts/flash", locals: { flash: flash })
          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :categorie_produit, :destroyed)
          redirect_to categorie_produits_url
        end
        format.json { head :no_content }
      end
    else
      respond_with_categorie_produit_destroy_blocked
    end
  rescue ActiveRecord::DeleteRestrictionError, ActiveRecord::InvalidForeignKey
    respond_with_categorie_produit_destroy_blocked
  end

  private

    def respond_with_categorie_produit_destroy_blocked
      admin_push_domain_toast!(flash.now, :categorie_produit, :destroy_blocked)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash", partial: "layouts/flash", locals: { flash: flash })
        end
        format.html do
          admin_push_domain_toast!(flash, :categorie_produit, :destroy_blocked)
          redirect_back fallback_location: admin_categorie_produits_url
        end
      end
    end

    def set_categorie_produit
      @categorie_produit = CategorieProduit.find(params[:id])
    end

    def categorie_produit_params
      params.require(:categorie_produit).permit(:nom, :service, :texte_annonce, :label, :image1)
    end


end
