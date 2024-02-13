class AvoirRembsController < ApplicationController
  before_action :set_avoir_remb, only: %i[ show edit update destroy ]

  # GET /avoir_rembs or /avoir_rembs.json
  def index
    @avoir_rembs = AvoirRemb.all
  end

  # GET /avoir_rembs/1 or /avoir_rembs/1.json
  def show
  end

  # GET /avoir_rembs/new
  def new
    @avoir_remb = AvoirRemb.new
  end

  # GET /avoir_rembs/1/edit
  def edit
    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@avoir_remb, 
          partial: "avoir_rembs/form", 
          locals: {commande_id: @avoir_remb.commande_id, avoir_remb: @avoir_remb})
      end
    end
  end

  # POST /avoir_rembs or /avoir_rembs.json
  def create
    @avoir_remb = AvoirRemb.new(avoir_remb_params)

    respond_to do |format|
      if @avoir_remb.save

        flash.now[:success] = "avoir remboursement was successfully created"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
                                partial: "avoir_rembs/form",
                                locals: { commande_id: @avoir_remb.commande.id, avoir_remb: AvoirRemb.new }),
  
            turbo_stream.append('avoir_rembs',
                                  partial: "avoir_rembs/avoir_remb",
                                  locals: { avoir_remb: @avoir_remb }),
            
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end

        format.html { redirect_to avoir_remb_url(@avoir_remb), notice: "Avoir remb was successfully created." }
        format.json { render :show, status: :created, location: @avoir_remb }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @avoir_remb.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /avoir_rembs/1 or /avoir_rembs/1.json
  def update
    respond_to do |format|
      if @avoir_remb.update(avoir_remb_params)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@avoir_remb, partial: "avoir_rembs/avoir_remb", locals: {avoir_remb: @avoir_remb}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash }),
    
          ]
        end

        format.html { redirect_to avoir_remb_url(@avoir_remb), notice: "Avoir remb was successfully updated." }
        format.json { render :show, status: :ok, location: @avoir_remb }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @avoir_remb.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /avoir_rembs/1 or /avoir_rembs/1.json
  def destroy
    @avoir_remb.destroy!

    respond_to do |format|

      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@avoir_remb)
        ]
      end 

      format.html { redirect_to avoir_rembs_url, notice: "Avoir remb was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_avoir_remb
      @avoir_remb = AvoirRemb.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def avoir_remb_params
      params.require(:avoir_remb).permit(:type_avoir_remb, :montant, :nature, :commande_id)
    end
end
