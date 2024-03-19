class HomeAdminController < ApplicationController

  before_action :authenticate_vendeur_or_admin!


  def index
    @clients = Client.limit(6)
    @commandes = Commande.limit(6)
    @produits = Produit.limit(6)
    @meetings = Meeting.limit(6)

  end

  private 

  def authenticate_vendeur_or_admin!
    unless current_user && (current_user.vendeur? || current_user.admin?)
      render "home_admin/demande_connexion", alert: "Vous n'avez pas accès à cette page. Veuillez vous connecter."
    end
  end
end
