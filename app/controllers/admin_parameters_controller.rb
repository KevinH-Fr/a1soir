class AdminParametersController < ApplicationController

  before_action :authenticate_admin!
  before_action :set_admin_parameter, only: %i[ show edit update destroy ]

  # GET /admin_parameters or /admin_parameters.json
  def index
    @admin_parameters = AdminParameter.all
  end

  # GET /admin_parameters/1 or /admin_parameters/1.json
  def show
  end

  # GET /admin_parameters/new
  def new
    @admin_parameter = AdminParameter.new
  end

  # GET /admin_parameters/1/edit
  def edit
    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@admin_parameter, 
          partial: "admin_parameters/form", 
          locals: {admin_parameter: @admin_parameter})
      end
    end
  end

  # POST /admin_parameters or /admin_parameters.json
  def create
    @admin_parameter = AdminParameter.new(admin_parameter_params)

    respond_to do |format|
      if @admin_parameter.save
        format.html { redirect_to admin_parameter_url(@admin_parameter), notice:  "Création à jour réussie" }
        format.json { render :show, status: :created, location: @admin_parameter }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @admin_parameter.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /admin_parameters/1 or /admin_parameters/1.json
  def update
    respond_to do |format|
      if @admin_parameter.update(admin_parameter_params)
        format.html { redirect_to admin_parameter_url(@admin_parameter), notice:  "Mise à jour réussie" }
        format.json { render :show, status: :ok, location: @admin_parameter }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_parameter.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /admin_parameters/1 or /admin_parameters/1.json
  def destroy
    @admin_parameter.destroy!

    respond_to do |format|
      format.html { redirect_to admin_parameters_url, notice:  "Suppression réussie"  }
      format.json { head :no_content }
    end
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def set_admin_parameter
      @admin_parameter = AdminParameter.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def admin_parameter_params
      params.require(:admin_parameter).permit(:tx_tva, :coef_prix_achat_vente, :coef_longue_duree, :duree_rdv)
    end
end
