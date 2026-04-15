class Admin::CouleursController < Admin::ApplicationController
  
  before_action :authenticate_admin!
  before_action :set_couleur, only: %i[ show edit update destroy ]

  def index
    @count_couleurs = Couleur.count

    search_params = params.permit(:format, :page, 
      q:[:nom_cont])
    @q = Couleur.ransack(search_params[:q])
    couleurs = @q.result(distinct: true).order(created_at: :desc)
    @pagy, @couleurs = pagy_countless(couleurs, items: 2)

  end

  def show
  end

  def new
    @couleur = Couleur.new
  end

  def edit

    respond_to do |format|
      format.html 
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          @couleur,
          partial: "admin/couleurs/form",
          locals: { couleur: @couleur, admin_form_row_embedded: true }
        )
      end
    end
  end

  def create
    @couleur = Couleur.new(couleur_params)

    respond_to do |format|
      if @couleur.save

        admin_push_domain_toast!(flash.now, :couleur, :created)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("new",
                                partial: "admin/couleurs/form",
                                locals: { couleur: Couleur.new, index_collapse: true }),
  
            turbo_stream.prepend('couleurs',
                                  partial: "admin/couleurs/couleur",
                                  locals: { couleur: @couleur }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :couleur, :created)
          redirect_to couleur_url(@couleur)
        end
        format.json { render :show, status: :created, location: @couleur }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @couleur.errors, status: :unprocessable_entity }
      end
    end
  end

  def update

    respond_to do |format|
      if @couleur.update(couleur_params)

        admin_push_domain_toast!(flash.now, :couleur, :updated)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@couleur, partial: "admin/couleurs/couleur", locals: {couleur: @couleur}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :couleur, :updated)
          redirect_to couleur_url(@couleur)
        end
        format.json { render :show, status: :ok, location: @couleur }
      else

        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            @couleur,
            partial: "admin/couleurs/form",
            locals: { couleur: @couleur, admin_form_row_embedded: true }
          )
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @couleur.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    unless @couleur.hard_destroy_allowed?
      admin_push_domain_toast!(flash, :couleur, :destroy_blocked)
      redirect_back fallback_location: admin_couleurs_url
      return
    end

    @couleur.destroy!

    respond_to do |format|
      format.html do
        admin_push_domain_toast!(flash, :couleur, :destroyed)
        redirect_to couleurs_url
      end
      format.json { head :no_content }
    end
  rescue ActiveRecord::DeleteRestrictionError, ActiveRecord::InvalidForeignKey
    admin_push_domain_toast!(flash, :couleur, :destroy_blocked)
    redirect_back fallback_location: admin_couleurs_url
  end

  private
    def set_couleur
      @couleur = Couleur.find(params[:id])
    end

    def couleur_params
      params.require(:couleur).permit(:nom, :couleur_code)
    end

end
