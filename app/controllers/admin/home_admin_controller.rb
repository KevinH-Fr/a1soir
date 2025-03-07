class Admin::HomeAdminController < Admin::ApplicationController

  #before_action :authenticate_vendeur_or_admin!

  def index
    @clients = Client.limit(6)
    @commandes = Commande.limit(6).includes([:client])
    @produits = Produit.limit(6).includes([:couleur], [:taille])
    @meetings = Meeting.limit(6).includes([:client], [:commande])

  end

  def selection_qr
  end


end
