class StockAchatsAnnuelsService < ApplicationService
  def initialize(year)
    @year = year.to_i
    @range = Date.new(@year, 1, 1)..Date.new(@year, 12, 31)
  end

  def call
    achat_rows = Produit
                .includes(:fournisseur)
                .where(dateachat: @range)
                .order(:dateachat, :nom)
                .map do |produit|
      quantite = produit.quantite.to_i
      prixachat = produit.prixachat.to_d
      montant_achat = prixachat * quantite

      {
        produit_id: produit.id,
        produit_nom: produit.nom,
        fournisseur_nom: produit.fournisseur&.nom,
        dateachat: produit.dateachat,
        prixachat: prixachat,
        quantite: quantite,
        montant_achat: montant_achat
      }
    end

    par_fournisseur_rows = achat_rows
                           .group_by { |row| row[:fournisseur_nom].presence || "Sans fournisseur" }
                           .map do |fournisseur_nom, rows|
      {
        fournisseur_nom: fournisseur_nom,
        produits_count: rows.size,
        quantite_totale: rows.sum { |row| row[:quantite] },
        montant_total: rows.sum { |row| row[:montant_achat] }
      }
    end
                           .sort_by { |row| row[:fournisseur_nom].downcase }

    {
      year: @year,
      rows: achat_rows,
      total_montant_achats: achat_rows.sum { |row| row[:montant_achat] },
      par_fournisseur: {
        year: @year,
        rows: par_fournisseur_rows,
        total_montant_achats: par_fournisseur_rows.sum { |row| row[:montant_total] }
      }
    }
  end
end
