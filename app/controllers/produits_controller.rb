class ProduitsController < ApplicationController
  before_action :set_produit, only: %i[ show edit update destroy ]

  # GET /produits or /produits.json
  def index
    @produits = Produit.all
    @categorie_produits = CategorieProduit.all
  end

  # GET /produits/1 or /produits/1.json
  def show
  end

  # GET /produits/new
  def new
    @produit = Produit.new
    @categorie_produits = CategorieProduit.all

  end

  # GET /produits/1/edit
  def edit
    @categorie_produits = CategorieProduit.all

    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@produit, 
          partial: "produits/form", 
          locals: {produit: @produit})
      end
    end
  end

  # POST /produits or /produits.json
  def create
    @produit = Produit.new(produit_params)

    respond_to do |format|
      if @produit.save

        flash.now[:success] = "produit was successfully created"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
                                partial: "produits/form",
                                locals: { produit: Produit.new }),
  
            turbo_stream.prepend('produits',
                                  partial: "produits/produit",
                                  locals: { produit: @produit }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end

        format.html { redirect_to produit_url(@produit), notice: "Produit was successfully created." }
        format.json { render :show, status: :created, location: @produit }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @produit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /produits/1 or /produits/1.json
  def update
    @categorie_produits = CategorieProduit.all

    respond_to do |format|
      if @produit.update(produit_params)

        flash.now[:success] = "produit was successfully updated"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@produit, partial: "produits/produit", locals: {produit: @produit}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html { redirect_to produit_url(@produit), notice: "Produit was successfully updated." }
        format.json { render :show, status: :ok, location: @produit }
      else

        format.turbo_stream do
          render turbo_stream: turbo_stream.update(@produit, 
                    partial: 'produits/form', 
                    locals: { produit: @produit })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @produit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /produits/1 or /produits/1.json
  def destroy
    @produit.destroy!

    respond_to do |format|
      format.html { redirect_to produits_url, notice: "Produit was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_produit
      @produit = Produit.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def produit_params
      params.require(:produit).permit(:nom, :prixvente, :prixlocation, :description, :categorie_produit_id, :caution, :handle, :reffrs, :quantite, :fournisseur_id, :dateachat, :prixachat, 
        :image1, :images)
    end
end
