class Admin::TypeProduitsController < Admin::ApplicationController

  before_action :authenticate_admin!
  before_action :set_type_produit, only: %i[ show edit update destroy ]

  def index

    @count_type_produits = TypeProduit.count

    search_params = params.permit(:format, :page, 
      q:[:nom_cont])
    @q = TypeProduit.ransack(search_params[:q])
    type_produits = @q.result(distinct: true).order(created_at: :desc)
    @pagy, @type_produits = pagy_countless(type_produits, items: 2)

  end

  def show
  end

  def new
    @type_produit = TypeProduit.new
  end

  def edit
    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@type_produit,
          partial: "admin/type_produits/form",
          locals: { type_produit: @type_produit, admin_form_row_embedded: true })
      end
    end
  end

  def create
    @type_produit = TypeProduit.new(type_produit_params)

    respond_to do |format|
      if @type_produit.save

        admin_push_domain_toast!(flash.now, :type_produit, :created)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
                               partial: "admin/type_produits/form",
                                locals: { type_produit: TypeProduit.new, index_collapse: true }),
  
            turbo_stream.prepend('type_produits',
                                  partial: "admin/type_produits/type_produit",
                                  locals: { type_produit: @type_produit }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
        ]
        end

        format.html do
          admin_push_domain_toast!(flash, :type_produit, :created)
          redirect_to type_produit_url(@type_produit)
        end
        format.json { render :show, status: :created, location: @type_produit }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @type_produit.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @type_produit.update(type_produit_params)

        admin_push_domain_toast!(flash.now, :type_produit, :updated)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@type_produit, partial: "admin/type_produits/type_produit", locals: {type_produit: @type_produit}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :type_produit, :updated)
          redirect_to type_produit_url(@type_produit)
        end
        format.json { render :show, status: :ok, location: @type_produit }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(@type_produit,
                    partial: 'admin/type_produits/form',
                    locals: { type_produit: @type_produit, admin_form_row_embedded: true })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @type_produit.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    unless @type_produit.hard_destroy_allowed?
      admin_push_domain_toast!(flash, :type_produit, :destroy_blocked)
      redirect_back fallback_location: admin_type_produits_url
      return
    end

    @type_produit.destroy!

    respond_to do |format|
      format.html do
        admin_push_domain_toast!(flash, :type_produit, :destroyed)
        redirect_to type_produits_url
      end
      format.json { head :no_content }
    end
  rescue ActiveRecord::DeleteRestrictionError, ActiveRecord::InvalidForeignKey
    admin_push_domain_toast!(flash, :type_produit, :destroy_blocked)
    redirect_back fallback_location: admin_type_produits_url
  end

  private
    def set_type_produit
      @type_produit = TypeProduit.find(params[:id])
    end

    def type_produit_params
      params.require(:type_produit).permit(:nom)
    end

end
