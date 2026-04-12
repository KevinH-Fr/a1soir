class Admin::AvoirRembsController < Admin::ApplicationController

  #before_action :authenticate_vendeur_or_admin!

  before_action :set_avoir_remb, only: %i[edit update destroy]

  # GET /avoir_rembs or /avoir_rembs.json
  def index
    @avoir_rembs = AvoirRemb.all
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
          partial: "admin/avoir_rembs/form",
          locals: {
            commande_id: @avoir_remb.commande_id,
            avoir_remb: @avoir_remb,
            admin_form_row_embedded: true
          })
      end
    end
  end

  # POST /avoir_rembs or /avoir_rembs.json
  def create
    @avoir_remb = AvoirRemb.new(avoir_remb_params)

    respond_to do |format|
      if @avoir_remb.save

        @commande = @avoir_remb.commande

        admin_push_domain_toast!(flash.now, :avoir_remb, :created)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("new_avoir_remb",
              partial: "admin/avoir_rembs/form",
              locals: {
                commande_id: @avoir_remb.commande.id,
                avoir_remb: AvoirRemb.new,
                admin_form_row_embedded: true
              }),

            turbo_stream.append("avoir_rembs",
              partial: "admin/avoir_rembs/avoir_remb",
              locals: { avoir_remb: @avoir_remb }),

            turbo_stream.update("synthese-avoirrembs",
              partial: "admin/avoir_rembs/synthese",
              locals: { avoir_rembs: @commande.avoir_rembs }),

            turbo_stream.update("synthese-commande",
              partial: "admin/commandes/synthese"),

            turbo_stream.prepend("flash", partial: "layouts/flash", locals: { flash: flash })

          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :avoir_remb, :created)
          redirect_to admin_commande_path(@avoir_remb.commande)
        end
        format.json { render json: @avoir_remb, status: :created, location: polymorphic_url([:admin, @avoir_remb]) }
      else
        format.turbo_stream do
          render turbo_stream:
            turbo_stream.update("new_avoir_remb",
              partial: "admin/avoir_rembs/form",
              locals: {
                commande_id: @avoir_remb.commande_id,
                avoir_remb: @avoir_remb,
                admin_form_row_embedded: true
              })
        end

        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @avoir_remb.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /avoir_rembs/1 or /avoir_rembs/1.json
  def update

    @commande = @avoir_remb.commande

    respond_to do |format|
      if @avoir_remb.update(avoir_remb_params)

        admin_push_domain_toast!(flash.now, :avoir_remb, :updated)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@avoir_remb,
              partial: "admin/avoir_rembs/avoir_remb",
              locals: { avoir_remb: @avoir_remb }),

            turbo_stream.update("synthese-commande",
              partial: "admin/commandes/synthese"),

            turbo_stream.update("synthese-avoirrembs",
              partial: "admin/avoir_rembs/synthese",
              locals: { avoir_rembs: @commande.avoir_rembs }),

            turbo_stream.prepend("flash",
              partial: "layouts/flash",
              locals: { flash: flash })

          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :avoir_remb, :updated)
          redirect_to admin_commande_path(@avoir_remb.commande)
        end
        format.json { render json: @avoir_remb, status: :ok, location: polymorphic_url([:admin, @avoir_remb]) }
      else
        format.turbo_stream do
          render turbo_stream:
            turbo_stream.update(@avoir_remb,
              partial: "admin/avoir_rembs/form",
              locals: {
                commande_id: @avoir_remb.commande_id,
                avoir_remb: @avoir_remb,
                admin_form_row_embedded: true
              })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @avoir_remb.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /avoir_rembs/1 or /avoir_rembs/1.json
  def destroy
    @commande = @avoir_remb.commande
    @avoir_remb.destroy!

    respond_to do |format|
      admin_push_domain_toast!(flash.now, :avoir_remb, :destroyed)

      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@avoir_remb),

          turbo_stream.update("synthese-avoirrembs",
            partial: "admin/avoir_rembs/synthese",
            locals: { avoir_rembs: @commande.avoir_rembs }),

          turbo_stream.update("synthese-commande",
            partial: "admin/commandes/synthese"),

          turbo_stream.prepend("flash", partial: "layouts/flash", locals: { flash: flash })
        ]
      end

      format.html do
        admin_push_domain_toast!(flash, :avoir_remb, :destroyed)
        redirect_to admin_commande_path(@commande)
      end
      format.json { head :no_content }
    end
  end

  private

    def set_avoir_remb
      @avoir_remb = AvoirRemb.find(params[:id])
    end

    def avoir_remb_params
      params.require(:avoir_remb).permit(:type_avoir_remb, :montant, :nature, :commande_id, :custom_date)
    end

end
