class Admin::AdminParametersController < Admin::ApplicationController

  before_action :authenticate_admin!
  before_action :set_admin_parameter, only: %i[ show edit update destroy ]

  def index
    @admin_parameters = AdminParameter.all
  end

  def show
  end

  def new
    @admin_parameter = AdminParameter.new
  end

  def edit
    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@admin_parameter, 
          partial: "admin/admin_parameters/form", 
          locals: {admin_parameter: @admin_parameter})
      end
    end
  end

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

  def update
    respond_to do |format|
      if @admin_parameter.update(admin_parameter_params)
        format.html { redirect_to admin_admin_parameter_url(@admin_parameter), notice:  "Mise à jour réussie" }
        format.json { render :show, status: :ok, location: @admin_parameter }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @admin_parameter.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @admin_parameter.destroy!

    respond_to do |format|
      format.html { redirect_to admin_parameters_url, notice:  "Suppression réussie"  }
      format.json { head :no_content }
    end
  end

  private

    def set_admin_parameter
      @admin_parameter = AdminParameter.find(params[:id])
    end

    def admin_parameter_params
      params.require(:admin_parameter).permit(:tx_tva, :coef_prix_achat_vente, :coef_longue_duree, :duree_rdv)
    end
end
