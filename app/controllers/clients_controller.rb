class ClientsController < ApplicationController

  before_action :authenticate_vendeur_or_admin!
  before_action :set_client, only: %i[ show edit update destroy ]

  def index
    @count_clients = Client.count

    search_params = params.permit(:format, :page, 
      q:[:nom_or_prenom_cont])
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
          partial: "clients/form", 
          locals: {client: @client})
      end
    end

  end

  def create
    @client = Client.new(client_params)

    respond_to do |format|
      if @client.save

      #  flash.now[:success] = "Client was successfully created"

       # format.turbo_stream do
       #   render turbo_stream: [
       #     turbo_stream.update('new',
       #                         partial: "clients/form",
       #                         locals: { client: Client.new }),
  
       #     turbo_stream.prepend('clients',
       #                           partial: "clients/client",
       #                           locals: { client: @client }),
       #     turbo_stream.prepend('flash', partial: 'layouts/flash', locals: { flash: flash })
            
       #  ]
       # end

        format.html { redirect_to client_url(@client), notice:  "Création à jour réussie"}
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

        flash.now[:success] =  "Mise à jour réussie"

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
      format.html { redirect_to clients_url, notice:  "Suppression réussie" }
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
      params.require(:client).permit(:prenom, :nom, :commentaires, :propart, :intitule, 
        :tel, :tel2, :mail, :mail2, :adresse, :cp, :ville, :pays, :contact, :language)
    end


end
