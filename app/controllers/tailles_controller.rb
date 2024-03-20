class TaillesController < ApplicationController
  before_action :authenticate_vendeur_or_admin!

  before_action :set_taille, only: %i[ show edit update destroy ]

  def index
    @q = Taille.ransack(params[:q])
    @tailles = @q.result(distinct: true)
  end

  def show
  end

  def new
    @taille = Taille.new
  end

  def edit

    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@taille, 
          partial: "tailles/form", 
          locals: {taille: @taille})
      end
    end
  end

  def create
    @taille = Taille.new(taille_params)

    respond_to do |format|
      if @taille.save

        flash.now[:success] =  I18n.t('notices.successfully_created')

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
                                partial: "tailles/form",
                                locals: { taille: Taille.new }),
  
            turbo_stream.prepend('tailles',
                                  partial: "tailles/taille",
                                  locals: { taille: @taille }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end

        format.html { redirect_to taille_url(@taille), notice: "taille was successfully created." }
        format.json { render :show, status: :created, location: @taille }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @taille.errors, status: :unprocessable_entity }
      end
    end
  end

  def update

    respond_to do |format|
      if @taille.update(taille_params)

        flash.now[:success] = I18n.t('notices.successfully_updated')

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@taille, partial: "tailles/taille", locals: {taille: @taille}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html { redirect_to taille_url(@taille), notice: "taille was successfully updated." }
        format.json { render :show, status: :ok, location: @taille }
      else

        format.turbo_stream do
          render turbo_stream: turbo_stream.update(@taille, 
                    partial: 'tailles/form', 
                    locals: { taille: @taille })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @taille.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tailles/1 or /tailles/1.json
  def destroy
    @taille.destroy!

    respond_to do |format|
      format.html { redirect_to tailles_url, notice: I18n.t('notices.successfully_destroyed')  }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_taille
      @taille = Taille.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def taille_params
      params.require(:taille).permit(:nom)
    end

end
