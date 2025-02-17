class Admin::TextesController < Admin::ApplicationController

  before_action :authenticate_admin!
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
    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@texte, 
          partial: "admin/textes/form", 
          locals: {texte: @texte})
      end
    end
  end

  def create
    @texte = Texte.new(texte_params)

    respond_to do |format|
      if @texte.save
        format.html { redirect_to admin_textes_url, notice:  "Création à jour réussie" }
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
        format.html { redirect_to admin_textes_url, notice:  "Mise à jour réussie" }
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
      format.html { redirect_to admin_textes_url, notice:  "Suppression réussie"  }
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
      params.require(:texte).permit(:titre, :boutique, :contact, :horaire, :adresse)
    end

end
