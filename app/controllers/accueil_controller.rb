class AccueilController < ApplicationController
  layout 'public' # utiliser le layout specific pour la partie site public

    def mariees
      @produits = Produit.categorie_robes_mariees.showed_vitrine
    end

    def costumes
      @produits = Produit.categorie_costumes_hommes.showed_vitrine
    end

    def soirees
      @produits = Produit.categorie_robes_soirees.showed_vitrine
    end

    def accessoires
      @produits = Produit.categorie_accessoires.showed_vitrine
    end

    def deguisements
      @produits = Produit.categorie_costumes_deguisements.showed_vitrine
    end

    def index
      @label = Label.last.principale
    end
  
  end
  