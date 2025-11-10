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
          locals: {client: @client})
      end
    end
  end

  def create
    @client = Client.new(client_params)

    respond_to do |format|
      if @client.save

        format.html { redirect_to admin_client_url(@client), notice:  "Création à jour réussie"}
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

        flash.now[:success] =  "Mise à jour réussie"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@client, partial: "admin/clients/client", locals: {client: @client}),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
          ]
        end

        format.html { redirect_to client_url(@client), notice: "Client was successfully updated." }
        format.json { render :show, status: :ok, location: @client }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @client.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @client.destroy!

    respond_to do |format|
      format.html { redirect_to admin_clients_url, notice:  "Suppression réussie" }
      format.json { head :no_content }
    end
  end

  private
    def set_client
      @client = Client.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def client_params
      params.require(:client).permit(:prenom, :nom, :commentaires, :propart, :intitule, 
        :tel, :tel2, :mail, :mail2, :adresse, :cp, :ville, :pays, :contact, :language)
    end


end
