module Public
  class PagesController < ApplicationController
    layout 'public' 

    def home
      @categories = CategorieProduit.all
    end

    def categories
    end

    def produits
    end

    def about
    end

    def contact
    end

  end
end
