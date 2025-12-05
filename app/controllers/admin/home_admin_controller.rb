class Admin::HomeAdminController < Admin::ApplicationController

  #before_action :authenticate_vendeur_or_admin!

  def index

    # remise a zero du type de selection qr ou non
    session[:display_qr_activated] = false 

    @clients = Client.limit(6)
    @commandes = Commande.limit(6).includes([:client])
    @produits = Produit.limit(6).includes([:couleur], [:taille])
    @meetings = Meeting.where('datedebut >= ?', Time.current).order(datedebut: :asc).limit(6).includes([:client], [:commande])

  end

  def selection_qr
  end


end
