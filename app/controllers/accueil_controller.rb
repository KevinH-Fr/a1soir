class AccueilController < ApplicationController
  layout 'public' # utiliser le layout specific pour la partie site public

    def mariees
      @produits = Produit.categorie_robes_mariees.showed_vitrine
    end

    def costumes
      @produits = Produit.categorie_costumes_hommes.showed_vitrine
    end

    def index
    end
  
  end
  