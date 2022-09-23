class AccueilController < ApplicationController
  layout 'public' # utiliser le layout specific pour la partie site public

    def mariees
      @produits = Produit.categorie_robes_mariees
    end

    def costumes
      @produits = Produit.categorie_costumes_hommes
    end

    def index
    end
  
  end
  