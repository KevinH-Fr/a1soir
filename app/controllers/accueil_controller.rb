class AccueilController < ApplicationController
  layout 'public' # utiliser le layout specific pour la partie site public

    def index
      @clients = Client.all
    end
  
  end
  