class HomeAdminController < ApplicationController

  before_action :authenticate_user!

  def index
    @clients = Client.limit(6)
    @commandes = Commande.limit(6)
    @produits = Produit.limit(6)
    @meetings = Meeting.limit(6)

  end
end
