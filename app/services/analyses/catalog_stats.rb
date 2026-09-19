# frozen_string_literal: true

module Analyses
  # Stats catalogue : top produits et répartitions type / catégorie (une catégorie par produit).
  class CatalogStats < ApplicationService
    TOP_LIMIT = 10
    CHART_TOP_LIMIT = 5
    SANS_CATEGORIE_LABEL = "Sans catégorie"
    SANS_TYPE_LABEL = "Sans type"
    # Une vente / location compte une seule fois : catégorie = première liée au produit (nom A→Z, puis id).
    CATEGORIE_ATTRIBUTION_NOTICE =
      "Répartition par catégorie : une seule catégorie par produit — la première par ordre alphabétique du nom " \
      "(pas de double comptage pour les produits multi-catégories)."

    def initialize(articles_scope, stripe_items_scope: StripePaymentItem.none, limit: TOP_LIMIT, chart_limit: CHART_TOP_LIMIT)
      @line_metrics = LineMetrics.new(
        articles_scope: articles_scope,
        stripe_items_scope: stripe_items_scope
      )
      @limit = limit
      @chart_limit = chart_limit
    end

    # ApplicationService.call ignore les kwargs Ruby 3 — overload explicite.
    def self.call(articles_scope, stripe_items_scope: StripePaymentItem.none, limit: TOP_LIMIT, chart_limit: CHART_TOP_LIMIT)
      new(articles_scope, stripe_items_scope: stripe_items_scope, limit: limit, chart_limit: chart_limit).call
    end

    def call
      by_produit = aggregate_by_produit
      top_by_qty = top_products_from(by_produit, primary: :quantite, secondary: :ca_lignes)
      {
        top_products: top_by_qty,
        top_products_by_qty: top_by_qty,
        top_products_by_ca: top_products_from(by_produit, primary: :ca_lignes, secondary: :quantite),
        by_type: rollup_by_type(by_produit, primary: :quantite, secondary: :ca_lignes),
        by_type_by_ca: rollup_by_type(by_produit, primary: :ca_lignes, secondary: :quantite),
        by_categorie: rollup_by_categorie(by_produit, primary: :quantite, secondary: :ca_lignes),
        by_categorie_by_ca: rollup_by_categorie(by_produit, primary: :ca_lignes, secondary: :quantite),
        categorie_attribution_notice: CATEGORIE_ATTRIBUTION_NOTICE
      }
    end

    private

    def aggregate_by_produit
      aggregates = @line_metrics.aggregate_by_produit
      quantites = aggregates[:quantites]
      ca_lignes = aggregates[:ca_lignes]
      qte_loc = aggregates[:qte_loc] || {}
      qte_vente = aggregates[:qte_vente] || {}

      produit_ids = (quantites.keys + ca_lignes.keys).uniq
      produits = Produit.where(id: produit_ids)
                       .includes(:type_produit, :couleur, :taille, image1_attachment: :blob)
                       .index_by(&:id)

      produit_ids.filter_map do |produit_id|
        produit = produits[produit_id]
        next unless produit

        {
          produit_id: produit_id,
          produit: produit,
          quantite: quantites.fetch(produit_id, 0).to_i,
          qte_loc: qte_loc.fetch(produit_id, 0).to_i,
          qte_vente: qte_vente.fetch(produit_id, 0).to_i,
          ca_lignes: ca_lignes.fetch(produit_id, 0.to_d)
        }
      end
    end

    def top_products_from(by_produit, primary:, secondary:)
      by_produit
        .sort_by { |row| [-row[primary], -row[secondary]] }
        .first(@limit)
    end

    def rollup_by_type(by_produit, primary:, secondary:)
      buckets = Hash.new { |h, k| h[k] = { label: k, quantite: 0, ca_lignes: 0.to_d } }

      by_produit.each do |row|
        type = row[:produit].type_produit
        label = type&.nom.presence || SANS_TYPE_LABEL
        buckets[label][:quantite] += row[:quantite]
        buckets[label][:ca_lignes] += row[:ca_lignes]
      end

      buckets.values.sort_by { |b| [-b[primary], -b[secondary]] }.first(@chart_limit)
    end

    def rollup_by_categorie(by_produit, primary:, secondary:)
      produit_ids = by_produit.map { |r| r[:produit_id] }
      primary_cats = primary_categories_for(produit_ids)

      buckets = Hash.new { |h, k| h[k] = { label: k, quantite: 0, ca_lignes: 0.to_d } }

      by_produit.each do |row|
        label = primary_cats.fetch(row[:produit_id], SANS_CATEGORIE_LABEL)
        buckets[label][:quantite] += row[:quantite]
        buckets[label][:ca_lignes] += row[:ca_lignes]
      end

      buckets.values.sort_by { |b| [-b[primary], -b[secondary]] }.first(@chart_limit)
    end

    def primary_categories_for(produit_ids)
      return {} if produit_ids.blank?

      mapping = {}
      CategorieProduit
        .joins(:produits)
        .where(produits: { id: produit_ids })
        .order("categorie_produits.nom ASC", "categorie_produits.id ASC")
        .pluck("produits.id", "categorie_produits.nom")
        .each { |produit_id, nom| mapping[produit_id] ||= nom }

      mapping
    end
  end
end
