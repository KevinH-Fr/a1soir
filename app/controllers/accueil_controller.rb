class AccueilController < ApplicationController
  layout 'public'
  
    def index
      @clients = Client.all
    end
  
  end
  