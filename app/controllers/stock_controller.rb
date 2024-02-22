class StockController < ApplicationController
  def index
    @produits = Produit.all
  end
end
