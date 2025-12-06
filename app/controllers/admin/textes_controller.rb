class Admin::TextesController < Admin::ApplicationController

  before_action :authenticate_admin!
  before_action :set_texte, only: %i[ show edit update destroy delete_image_attachment ]

  def index
    @textes = Texte.all
    @coups_de_coeur = Produit.coups_de_coeur.includes(:image1_attachment, :categorie_produits)
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

    # Retain existing medias if the field is left empty
    if params[:texte][:carousel_images].present?
      params[:texte][:carousel_images].each do |image|
        @texte.carousel_images.attach(image)
      end
    end

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

  def delete_image_attachment
    @media = @texte.carousel_images.find(params[:image_id])
    @media.purge
  
    redirect_to admin_texte_path(@texte), notice: "Media has been deleted successfully."
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
      params.require(:texte).permit(:titre, :boutique, :contact, :horaire, :adresse, :equipe)
    end

end
