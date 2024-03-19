class StockController < ApplicationController
  before_action :authenticate_vendeur_or_admin!

  def index
    @produits = Produit.all
    @commandes = Commande.all
  end

end
