class StockVentesAnnuellesService < ApplicationService
  def initialize(year)
    @year = year.to_i
    @from = Date.new(@year, 1, 1).beginning_of_day
    @to = Date.new(@year, 12, 31).end_of_day
  end

  def call
    ventes = Hash.new { |h, k| h[k] = default_row }

    ventes_boutique_articles(ventes)
    ventes_boutique_sousarticles(ventes)
    ventes_eshop(ventes)
    hydrate_product_names!(ventes)

    rows = ventes.values.sort_by { |row| row[:produit_nom].to_s.downcase }

    {
      year: @year,
      rows: rows,
      total_quantite_boutique: rows.sum { |row| row[:quantite_boutique] },
      total_quantite_eshop: rows.sum { |row| row[:quantite_eshop] },
      total_quantite_globale: rows.sum { |row| row[:quantite_totale] },
      total_montant_boutique: rows.sum { |row| row[:montant_boutique] },
      total_montant_eshop: rows.sum { |row| row[:montant_eshop] },
      total_montant_global: rows.sum { |row| row[:montant_total] }
    }
  end

  private

  def default_row
    {
      produit_id: nil,
      produit_nom: nil,
      date_vente: nil,
      quantite_boutique: 0,
      quantite_eshop: 0,
      quantite_totale: 0,
      montant_boutique: 0.to_d,
      montant_eshop: 0.to_d,
      montant_total: 0.to_d
    }
  end

  def ventes_boutique_articles(ventes)
    Article
      .joins(:commande)
      .merge(Commande.hors_devis)
      .where(commandes: { eshop: [false, nil] })
      .vente_only
      .where(created_at: @from..@to)
      .pluck(:produit_id, :quantite, :prix, :created_at)
      .each do |produit_id, quantite, montant, date_vente|
      row = ventes[produit_id]
      row[:produit_id] = produit_id
      row[:quantite_boutique] += quantite.to_i
      row[:montant_boutique] += montant.to_d
      set_latest_sale_date!(row, date_vente)
    end
  end

  def ventes_boutique_sousarticles(ventes)
    Sousarticle
      .joins(article: :commande)
      .merge(Commande.hors_devis)
      .where(commandes: { eshop: [false, nil] })
      .vente_only
      .where(sousarticles: { created_at: @from..@to })
      .pluck(:produit_id, :prix, :created_at)
      .each do |produit_id, montant, date_vente|
      row = ventes[produit_id]
      row[:produit_id] = produit_id
      row[:quantite_boutique] += 1
      row[:montant_boutique] += montant.to_d
      set_latest_sale_date!(row, date_vente)
    end
  end

  def ventes_eshop(ventes)
    StripePaymentItem
      .joins(:stripe_payment)
      .where(stripe_payments: { status: "paid", created_at: @from..@to })
      .pluck(:produit_id, :quantity, :unit_amount, "stripe_payments.created_at")
      .each do |produit_id, quantity, unit_amount, date_vente|
      row = ventes[produit_id]
      row[:produit_id] = produit_id
      quantite = quantity.presence || 1
      row[:quantite_eshop] += quantite.to_i
      row[:montant_eshop] += ((quantite.to_i * unit_amount.to_i).to_d / 100)
      set_latest_sale_date!(row, date_vente)
    end

    ventes.each_value do |row|
      row[:quantite_totale] = row[:quantite_boutique] + row[:quantite_eshop]
      row[:montant_total] = row[:montant_boutique] + row[:montant_eshop]
    end
  end

  def hydrate_product_names!(ventes)
    names_by_id = Produit.where(id: ventes.keys).pluck(:id, :nom).to_h
    ventes.each do |produit_id, row|
      row[:produit_nom] = names_by_id[produit_id]
    end
  end

  def set_latest_sale_date!(row, date_vente)
    return if date_vente.blank?

    row[:date_vente] = date_vente if row[:date_vente].blank? || date_vente > row[:date_vente]
  end
end
