class ArticleoptionsController < ApplicationController
  before_action :set_articleoption, only: %i[ show edit update destroy ]

  # GET /articleoptions or /articleoptions.json
  def index
    @articleoptions = Articleoption.all
  end

  # GET /articleoptions/1 or /articleoptions/1.json
  def show
  end

  # GET /articleoptions/new
  def new
    @articleoption = Articleoption.new
  end

  # GET /articleoptions/1/edit
  def edit
  end

  # POST /articleoptions or /articleoptions.json
  def create
    @articleoption = Articleoption.new(articleoption_params)

    respond_to do |format|
      if @articleoption.save
        format.html { redirect_to articleoption_url(@articleoption), notice: "Articleoption was successfully created." }
        format.json { render :show, status: :created, location: @articleoption }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @articleoption.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /articleoptions/1 or /articleoptions/1.json
  def update
    respond_to do |format|
      if @articleoption.update(articleoption_params)
        format.html { redirect_to articleoption_url(@articleoption), notice: "Articleoption was successfully updated." }
        format.json { render :show, status: :ok, location: @articleoption }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @articleoption.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /articleoptions/1 or /articleoptions/1.json
  def destroy
    @articleoption.destroy

    respond_to do |format|
      format.html { redirect_to articleoptions_url, notice: "Articleoption was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_articleoption
      @articleoption = Articleoption.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def articleoption_params
      params.require(:articleoption).permit(:nature, :description, :prix, :caution, :taille)
    end
end
