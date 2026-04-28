class Admin::StockController < Admin::ApplicationController

 before_action :authenticate_admin!, only: %i[ index export_csv report ]

  def index
    @produits = Produit.all
  end

  def export_csv
    csv_content = InventaireCsvService.new(params[:year]).call

    send_data csv_content,
              filename: "inventaire_produits_#{params[:year]}_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
              type: 'text/csv; charset=utf-8'
  end

  def report
    @year = params[:year].presence&.to_i || Date.current.year

    report_data = Rails.cache.fetch("stock_report_annuel/#{@year}", expires_in: 10.minutes) do
      achats_data = StockAchatsAnnuelsService.call(@year)
      ventes_data = StockVentesAnnuellesService.call(@year)

      {
        year: @year,
        achats_data: achats_data,
        achats_par_fournisseur_data: achats_data[:par_fournisseur],
        ventes_data: ventes_data
      }
    end

    @achats_data = report_data[:achats_data]
    @achats_par_fournisseur_data = report_data[:achats_par_fournisseur_data]
    @ventes_data = report_data[:ventes_data]

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "reporting_stock_#{@year}_#{Time.current.strftime('%Y%m%d_%H%M%S')}",
               template: "admin/stock/report_pdf",
               formats: [:html],
               layout: "pdf",
               disposition: "inline"
      end
    end
  end

end
