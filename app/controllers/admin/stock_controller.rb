class Admin::StockController < Admin::ApplicationController
 # before_action :authenticate_vendeur_or_admin!

  def index
    @produits = Produit.all
    @commandes = Commande.all.includes([:articles])
  end

  def export_csv
    csv_content = InventaireCsvService.new(params[:year]).call

    send_data csv_content,
              filename: "inventaire_produits_#{params[:year]}_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
              type: 'text/csv; charset=utf-8'
  end

end
