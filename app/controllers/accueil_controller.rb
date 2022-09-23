class AccueilController < ApplicationController
  layout 'public' # utiliser le layout specific pour la partie site public

    def mariees
      @produits = Produit.all
    end

    def costumes
      @produits = Produit.all
    end

    def index
    end
  
  end
  