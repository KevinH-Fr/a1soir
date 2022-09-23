class AccueilAdminController < ApplicationController

    def index
      @clients = Client.all
      @produits = Produit.all
    end
  
  end
  