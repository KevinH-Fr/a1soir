class HomeAdminController < ApplicationController

  before_action :authenticate_vendeur_or_admin!

  def index
    @clients = Client.limit(6)
    @commandes = Commande.limit(6)
    @produits = Produit.limit(6)
    @meetings = Meeting.limit(6)


    respond_to do |format|
      format.html
      format.pdf do
       tmp = Tempfile.new
       browser = Ferrum::Browser.new
       browser.go_to("https://google.com")
       browser.pdf(path: tmp)
       browser.quit
       send_file tmp, type: "application/pdf", disposition: "inline"
      end
    end

  end

end
