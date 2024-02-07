class HomeAdminController < ApplicationController
  def index
    @clients = Client.limit(6)
    @commandes = Commande.limit(6)
    @produits = Produit.limit(6)

  end
end
