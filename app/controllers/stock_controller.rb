class StockController < ApplicationController
  def index
    @produits = Produit.all
    @commandes = Commande.all
  end
end
