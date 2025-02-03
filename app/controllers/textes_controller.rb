class TextesController < ApplicationController

  before_action :authenticate_vendeur_or_admin!
  before_action :set_texte, only: %i[ show edit update destroy ]

  def index
    @textes = Texte.all
  end

  def show
  end

  def new
    @texte = Texte.new
  end

  def edit
  end

  def create
    @texte = Texte.new(texte_params)

    respond_to do |format|
      if @texte.save
        format.html { redirect_to texte_url(@texte), notice:  "Création à jour réussie" }
        format.json { render :show, status: :created, location: @texte }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @texte.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @texte.update(texte_params)
        format.html { redirect_to texte_url(@texte), notice:  "Mise à jour réussie" }
        format.json { render :show, status: :ok, location: @texte }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @texte.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @texte.destroy!

    respond_to do |format|
      format.html { redirect_to textes_url, notice:  "Suppression réussie"  }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_texte
      @texte = Texte.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def texte_params
      params.require(:texte).permit(:titre, :content)
    end

end
