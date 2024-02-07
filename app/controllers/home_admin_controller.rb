class HomeAdminController < ApplicationController
  def index
    @clients = Client.limit(6)
  end
end
