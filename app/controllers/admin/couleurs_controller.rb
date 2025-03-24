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
        render turbo_stream: turbo_stream.update(@couleur, 
          partial: "admin/couleurs/form", 
          locals: {couleur: @couleur})
      end
    end
  end

  def create
    @couleur = Couleur.new(couleur_params)

    respond_to do |format|
      if @couleur.save

        flash.now[:success] =  "Création réussie"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
                                partial: "admin/couleurs/form",
                                locals: { couleur: Couleur.new }),
  
            turbo_stream.prepend('couleurs',
                                  partial: "admin/couleurs/couleur",
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

        flash.now[:success] = "Mise à jour réussie"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@couleur, partial: "admin/couleurs/couleur", locals: {couleur: @couleur}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html { redirect_to couleur_url(@couleur), notice: "couleur was successfully updated." }
        format.json { render :show, status: :ok, location: @couleur }
      else

        format.turbo_stream do
          render turbo_stream: turbo_stream.update(@couleur, 
                    partial: 'admin/couleurs/form', 
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
      format.html { redirect_to couleurs_url, notice:  "Suppression réussie"  }
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
