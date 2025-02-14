module Public
  class PagesController < ApplicationController
    layout 'public' 

    def home
      @categories = CategorieProduit.all
    end

    def categories
    end

    def categorie
      @categorie = CategorieProduit.find(params[:id])
      @produits = @categorie.produits
      # Group produits by handle and pick the first product for each unique handle
      @produits_uniques = @produits.group_by(&:handle).map { |_, produits| produits.first }

      # Get all associated tailles, remove nil values, and ensure uniqueness
      @tailles = @produits.map { |produit| produit.taille }.compact.uniq
            
      @categories = CategorieProduit.all
    end

    def produits
    end

    def produit
      @produit = Produit.find(params[:id])
      @tailles = [@produit.taille].compact.uniq
    end

    def about
    end

    def contact
    end

  end
end
