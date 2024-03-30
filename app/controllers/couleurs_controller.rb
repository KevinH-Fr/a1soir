class CouleursController < ApplicationController
  
  before_action :authenticate_vendeur_or_admin!
  before_action :set_couleur, only: %i[ show edit update destroy ]

  def index

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
        render turbo_stream: turbo_stream.update(@couleur, 
          partial: "couleurs/form", 
          locals: {couleur: @couleur})
      end
    end
  end

  def create
    @couleur = Couleur.new(couleur_params)

    respond_to do |format|
      if @couleur.save

        flash.now[:success] =  I18n.t('notices.successfully_created')

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
                                partial: "couleurs/form",
                                locals: { couleur: Couleur.new }),
  
            turbo_stream.prepend('couleurs',
                                  partial: "couleurs/couleur",
                                  locals: { couleur: @couleur }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end

        format.html { redirect_to couleur_url(@couleur), notice: "couleur was successfully created." }
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

        flash.now[:success] = I18n.t('notices.successfully_updated')

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@couleur, partial: "couleurs/couleur", locals: {couleur: @couleur}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html { redirect_to couleur_url(@couleur), notice: "couleur was successfully updated." }
        format.json { render :show, status: :ok, location: @couleur }
      else

        format.turbo_stream do
          render turbo_stream: turbo_stream.update(@couleur, 
                    partial: 'couleurs/form', 
                    locals: { couleur: @couleur })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @couleur.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @couleur.destroy!

    respond_to do |format|
      format.html { redirect_to couleurs_url, notice: I18n.t('notices.successfully_destroyed')  }
      format.json { head :no_content }
    end
  end

  private
    def set_couleur
      @couleur = Couleur.find(params[:id])
    end

    def couleur_params
      params.require(:couleur).permit(:nom, :couleur_code)
    end

end
