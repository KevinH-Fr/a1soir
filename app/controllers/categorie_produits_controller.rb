class CategorieProduitsController < ApplicationController
  before_action :set_categorie_produit, only: %i[ show edit update destroy ]

  # GET /categorie_produits or /categorie_produits.json
  def index
    @categorie_produits = CategorieProduit.all
  end

  # GET /categorie_produits/1 or /categorie_produits/1.json
  def show
  end

  # GET /categorie_produits/new
  def new
    @categorie_produit = CategorieProduit.new
  end

  # GET /categorie_produits/1/edit
  def edit
  end

  # POST /categorie_produits or /categorie_produits.json
  def create
    @categorie_produit = CategorieProduit.new(categorie_produit_params)

    respond_to do |format|
      if @categorie_produit.save
        format.html { redirect_to categorie_produit_url(@categorie_produit), notice: "Categorie produit was successfully created." }
        format.json { render :show, status: :created, location: @categorie_produit }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @categorie_produit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /categorie_produits/1 or /categorie_produits/1.json
  def update
    respond_to do |format|
      if @categorie_produit.update(categorie_produit_params)
        format.html { redirect_to categorie_produit_url(@categorie_produit), notice: "Categorie produit was successfully updated." }
        format.json { render :show, status: :ok, location: @categorie_produit }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @categorie_produit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /categorie_produits/1 or /categorie_produits/1.json
  def destroy
    @categorie_produit.destroy!

    respond_to do |format|
      format.html { redirect_to categorie_produits_url, notice: "Categorie produit was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_categorie_produit
      @categorie_produit = CategorieProduit.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def categorie_produit_params
      params.require(:categorie_produit).permit(:nom, :texte_annonce, :label)
    end
end
