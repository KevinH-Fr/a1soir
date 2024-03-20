class TypeProduitsController < ApplicationController

  before_action :authenticate_vendeur_or_admin!
  before_action :set_type_produit, only: %i[ show edit update destroy ]

  def index
    @q = TypeProduit.ransack(params[:q])
    @type_produits = @q.result(distinct: true)
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
          partial: "type_produits/form", 
          locals: {type_produit: @type_produit})
      end
    end
  end

  def create
    @type_produit = TypeProduit.new(type_produit_params)

    respond_to do |format|
      if @type_produit.save
        format.html { redirect_to type_produit_url(@type_produit), notice: "Type produit was successfully created." }
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
        format.html { redirect_to type_produit_url(@type_produit), notice: "Type produit was successfully updated." }
        format.json { render :show, status: :ok, location: @type_produit }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @type_produit.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @type_produit.destroy!

    respond_to do |format|
      format.html { redirect_to type_produits_url, notice: "Type produit was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    def set_type_produit
      @type_produit = TypeProduit.find(params[:id])
    end

    def type_produit_params
      params.require(:type_produit).permit(:nom)
    end

end
