class Admin::ClientsController < Admin::ApplicationController

  #before_action :authenticate_vendeur_or_admin!
  before_action :set_client, only: %i[ show edit update destroy ]

  def index
    @count_clients = Client.count

    search_params = params.permit(:format, :page, 
      q:[:nom_or_prenom_or_tel_or_tel2_or_mail_or_mail2_cont])
    @q = Client.ransack(search_params[:q])
    clients = @q.result(distinct: true).order(created_at: :desc)
    @pagy, @clients = pagy_countless(clients, items: 2)

  end

  
  def show
    @clients = Client.all
    @profiles = Profile.all 
  end

  def new
    @client = Client.new
  end

  def edit
    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@client, 
          partial: "admin/clients/form", 
          locals: {
            client: @client,
            admin_form_row_embedded: true,
            client_display_variant: params[:client_display_variant]
          })
      end
    end
  end

  def create
    @client = Client.new(client_params)

    respond_to do |format|
      if @client.save

        format.html do
          admin_push_domain_toast!(flash, :client, :created)
          redirect_to admin_client_url(@client)
        end
        format.json { render :show, status: :created, location: @client }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @client.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @client.update(client_params)

        admin_push_domain_toast!(flash.now, :client, :updated)

        format.turbo_stream do
          variant = params[:client_display_variant] == "mini" ? :mini : :full
          render turbo_stream: [
            turbo_stream.update(@client,
              partial: "admin/clients/client",
              locals: { client: @client, variant: variant, client_inner_only: true }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :client, :updated)
          redirect_to client_url(@client)
        end
        format.json { render :show, status: :ok, location: @client }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(@client,
            partial: "admin/clients/form",
            locals: {
              client: @client,
              admin_form_row_embedded: true,
              client_display_variant: params[:client_display_variant]
            })
        end

        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @client.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    unless @client.hard_destroy_allowed?
      respond_with_client_destroy_blocked
      return
    end

    if @client.destroy
      respond_to do |format|
        admin_push_domain_toast!(flash.now, :client, :destroyed)

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove(@client),
            turbo_stream.prepend("flash", partial: "layouts/flash", locals: { flash: flash })
          ]
        end

        format.html do
          admin_push_domain_toast!(flash, :client, :destroyed)
          redirect_to admin_clients_url
        end
        format.json { head :no_content }
      end
    else
      respond_with_client_destroy_blocked
    end
  rescue ActiveRecord::DeleteRestrictionError, ActiveRecord::InvalidForeignKey
    respond_with_client_destroy_blocked
  end

  private

    def respond_with_client_destroy_blocked
      admin_push_domain_toast!(flash.now, :client, :destroy_blocked)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash", partial: "layouts/flash", locals: { flash: flash })
        end
        format.html do
          admin_push_domain_toast!(flash, :client, :destroy_blocked)
          redirect_back fallback_location: admin_client_path(@client)
        end
      end
    end

    def set_client
      @client = Client.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def client_params
      params.require(:client).permit(:prenom, :nom, :commentaires, :propart, :intitule, 
        :tel, :tel2, :mail, :mail2, :adresse, :cp, :ville, :pays, :contact, :language)
    end


end
