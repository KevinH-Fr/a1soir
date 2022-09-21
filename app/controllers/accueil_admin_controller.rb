class AccueilAdminController < ApplicationController

    def index
      @clients = Client.all
    end
  
  end
  