class ClientsController < ApplicationController

  before_action :authenticate_vendeur_or_admin!

  before_action :set_client, only: %i[ show edit update destroy ]

  # GET /clients or /clients.json
  def index
    @clients = Client.all
  end

  # GET /clients/1 or /clients/1.json
  def show
  end

  # GET /clients/new
  def new
    @client = Client.new
  end

  def edit

    respond_to do |format|
      format.html 
      format.turbo_stream do  
        render turbo_stream: turbo_stream.update(@client, 
          partial: "clients/form", 
          locals: {client: @client})
      end
    end

  end

  # POST /clients or /clients.json
  def create
    @client = Client.new(client_params)

    respond_to do |format|
      if @client.save

        flash.now[:success] = "Client was successfully created"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update('new',
                                partial: "clients/form",
                                locals: { client: Client.new }),
  
            turbo_stream.prepend('clients',
                                  partial: "clients/client",
                                  locals: { client: @client }),
            turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
          ]
        end

        format.html { redirect_to client_url(@client), notice: "Client was successfully created." }
        format.json { render :show, status: :created, location: @client }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @client.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /clients/1 or /clients/1.json
  def update
    respond_to do |format|
      if @client.update(client_params)

        flash.now[:success] = "Client was successfully updated"

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update(@client, partial: "clients/client", locals: {client: @client}),
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

  # DELETE /clients/1 or /clients/1.json
  def destroy
    @client.destroy!

    respond_to do |format|
      format.html { redirect_to clients_url, notice: "Client was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_client
      @client = Client.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def client_params
      params.require(:client).permit(:prenom, :nom, :commentaires, :propart, :intitule, :tel, :tel2, :mail, :mail2, :adresse, :cp, :ville, :pays, :contact)
    end

    private

    def authenticate_vendeur_or_admin!
      unless current_user && (current_user.vendeur? || current_user.admin?)
        render "home_admin/demande_connexion", alert: "Vous n'avez pas accès à cette page. Veuillez vous connecter."
      end
    end

end
