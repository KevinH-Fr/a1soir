class TextesController < ApplicationController
  before_action :set_texte, only: %i[ show edit update destroy ]

  # GET /textes or /textes.json
  def index
    @textes = Texte.all
  end

  # GET /textes/1 or /textes/1.json
  def show
  end

  # GET /textes/new
  def new
    @texte = Texte.new
  end

  # GET /textes/1/edit
  def edit
  end

  # POST /textes or /textes.json
  def create
    @texte = Texte.new(texte_params)

    respond_to do |format|
      if @texte.save
        format.html { redirect_to texte_url(@texte), notice: "Texte was successfully created." }
        format.json { render :show, status: :created, location: @texte }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @texte.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /textes/1 or /textes/1.json
  def update
    respond_to do |format|
      if @texte.update(texte_params)
        format.html { redirect_to texte_url(@texte), notice: "Texte was successfully updated." }
        format.json { render :show, status: :ok, location: @texte }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @texte.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /textes/1 or /textes/1.json
  def destroy
    @texte.destroy!

    respond_to do |format|
      format.html { redirect_to textes_url, notice: "Texte was successfully destroyed." }
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
