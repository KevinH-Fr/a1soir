class FournisseursController < ApplicationController
  before_action :set_fournisseur, only: %i[ show edit update destroy ]

  # GET /fournisseurs or /fournisseurs.json
  def index
    @fournisseurs = Fournisseur.all
  end

  # GET /fournisseurs/1 or /fournisseurs/1.json
  def show
  end

  # GET /fournisseurs/new
  def new
    @fournisseur = Fournisseur.new
  end

  # GET /fournisseurs/1/edit
  def edit
    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@fournisseur, 
          partial: "fournisseurs/form", 
          locals: {fournisseur: @fournisseur})
      end
    end
  end

  # POST /fournisseurs or /fournisseurs.json
  def create
    @fournisseur = Fournisseur.new(fournisseur_params)

    respond_to do |format|
      if @fournisseur.save

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
                                partial: "fournisseurs/form",
                                locals: { fournisseur: Fournisseur.new }),
  
            turbo_stream.prepend('fournisseurs',
                                  partial: "fournisseurs/fournisseur",
                                  locals: { fournisseur: @fournisseur }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end

        format.html { redirect_to fournisseur_url(@fournisseur), notice: "Fournisseur was successfully created." }
        format.json { render :show, status: :created, location: @fournisseur }
      else


        format.turbo_stream { render turbo_stream: turbo_stream.replace(
          'fournisseur_form', 
          partial: 'fournisseurs/form', 
          locals: { fournisseur: @fournisseur }
        ) }

        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @fournisseur.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /fournisseurs/1 or /fournisseurs/1.json
  def update
    respond_to do |format|
      if @fournisseur.update(fournisseur_params)

        flash.now[:success] = "fournisseur was successfully created"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
                                partial: "fournisseurs/form",
                                locals: { fournisseur: Fournisseur.new }),
  
            turbo_stream.prepend('fournisseurs',
                                  partial: "fournisseurs/fournisseur",
                                  locals: { fournisseur: @fournisseur }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end

        format.html { redirect_to fournisseur_url(@fournisseur), notice: "Fournisseur was successfully updated." }
        format.json { render :show, status: :ok, location: @fournisseur }
      else

        format.turbo_stream do
          render turbo_stream: turbo_stream.update(@fournisseur, 
                    partial: 'fournisseurs/form', 
                    locals: { fournisseur: @fournisseur })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @fournisseur.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fournisseurs/1 or /fournisseurs/1.json
  def destroy
    @fournisseur.destroy!

    respond_to do |format|
      format.html { redirect_to fournisseurs_url, notice: "Fournisseur was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_fournisseur
      @fournisseur = Fournisseur.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def fournisseur_params
      params.require(:fournisseur).permit(:nom, :tel, :mail, :contact, :site, :notes)
    end
end
