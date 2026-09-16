# frozen_string_literal: true

module Analyses
  # Agrège lignes boutique (articles hors e-shop) + lignes Stripe e-shop (toujours vente).
  # Évite le double comptage : les articles liés à une commande e-shop sont ignorés.
  class LineMetrics
    def initialize(articles_scope:, stripe_items_scope: StripePaymentItem.none)
      @articles_scope = articles_scope
      @stripe_items_scope = stripe_items_scope
    end

    def boutique_articles
      @boutique_articles ||= @articles_scope.where(
        commande_id: Commande.where(eshop: [false, nil]).select(:id)
      )
    end

    def stripe_items
      @stripe_items_scope
    end

    def lignes_count
      @lignes_count ||= boutique_articles.count + stripe_items.count
    end

    def loc_lignes_count
      @loc_lignes_count ||= boutique_articles.where(locvente: "location").count
    end

    def vente_lignes_count
      @vente_lignes_count ||= boutique_articles.where(locvente: "vente").count + stripe_items.count
    end

    # Nb d'articles = somme des quantités (pas le nombre de lignes).
    def quantites
      @quantites ||= boutique_articles.sum(:quantite).to_i + stripe_items.sum(:quantity).to_i
    end

    def loc_quantites
      @loc_quantites ||= boutique_articles.where(locvente: "location").sum(:quantite).to_i
    end

    def vente_quantites
      @vente_quantites ||= boutique_articles.where(locvente: "vente").sum(:quantite).to_i +
                           stripe_items.sum(:quantity).to_i
    end

    def loc_ca_lignes
      @loc_ca_lignes ||= boutique_articles.where(locvente: "location").sum(:prix).to_d
    end

    def vente_ca_lignes
      @vente_ca_lignes ||= boutique_articles.where(locvente: "vente").sum(:prix).to_d + stripe_ca_lignes
    end

    def ca_lignes
      @ca_lignes ||= boutique_articles.sum(:prix).to_d + stripe_ca_lignes
    end

    def produits_count
      @produits_count ||= (
        boutique_articles.distinct.pluck(:produit_id) +
        stripe_items.distinct.pluck(:produit_id)
      ).uniq.size
    end

    def quantites_by_day
      article_days = boutique_articles
                     .group(Arel.sql("DATE(articles.created_at)"))
                     .order(Arel.sql("DATE(articles.created_at)"))
                     .sum(:quantite)
                     .transform_values(&:to_i)

      stripe_days = stripe_items_for_aggregation
                    .joins(:stripe_payment)
                    .group(Arel.sql("DATE(stripe_payments.created_at)"))
                    .order(Arel.sql("DATE(stripe_payments.created_at)"))
                    .sum(:quantity)
                    .transform_values(&:to_i)

      merge_day_ints(article_days, stripe_days)
    end

    def ca_lignes_by_day
      article_days = boutique_articles
                     .group(Arel.sql("DATE(articles.created_at)"))
                     .order(Arel.sql("DATE(articles.created_at)"))
                     .sum(:prix)
                     .transform_values(&:to_d)

      stripe_days = if stripe_items_empty?
                      {}
                    else
                      stripe_items_for_aggregation
                        .joins(:stripe_payment)
                        .group(Arel.sql("DATE(stripe_payments.created_at)"))
                        .order(Arel.sql("DATE(stripe_payments.created_at)"))
                        .sum(Arel.sql("stripe_payment_items.quantity * stripe_payment_items.unit_amount"))
                        .transform_values { |cents| cents.to_d / 100 }
                    end

      merge_day_decimals(article_days, stripe_days)
    end

    def stripe_ca_lignes
      return 0.to_d if stripe_items_empty?

      stripe_items_for_aggregation
        .sum(Arel.sql("stripe_payment_items.quantity * stripe_payment_items.unit_amount"))
        .to_d / 100
    end

    def aggregate_by_produit
      quantites = Hash.new(0)
      ca = Hash.new(0.to_d)
      qte_loc = Hash.new(0)
      qte_vente = Hash.new(0)

      boutique_articles.group(:produit_id).sum(:quantite).each do |produit_id, q|
        quantites[produit_id] += q.to_i
      end
      boutique_articles.where(locvente: "location").group(:produit_id).sum(:quantite).each do |produit_id, q|
        qte_loc[produit_id] += q.to_i
      end
      boutique_articles.where(locvente: "vente").group(:produit_id).sum(:quantite).each do |produit_id, q|
        qte_vente[produit_id] += q.to_i
      end
      boutique_articles.group(:produit_id).sum(:prix).each do |produit_id, amount|
        ca[produit_id] += amount.to_d
      end

      unless stripe_items_empty?
        items = stripe_items_for_aggregation
        items.group(:produit_id).sum(:quantity).each do |produit_id, q|
          q_i = q.to_i
          quantites[produit_id] += q_i
          qte_vente[produit_id] += q_i
        end
        items.group(:produit_id)
             .sum(Arel.sql("stripe_payment_items.quantity * stripe_payment_items.unit_amount"))
             .each do |produit_id, cents|
          ca[produit_id] += cents.to_d / 100
        end
      end

      { quantites: quantites, ca_lignes: ca, qte_loc: qte_loc, qte_vente: qte_vente }
    end

    private

    def stripe_items_empty?
      !stripe_items.exists?
    end

    # Scope plat pour éviter les doubles JOIN hérités de DashboardScopes.
    def stripe_items_for_aggregation
      StripePaymentItem.where(id: stripe_items.reselect(:id))
    end

    def merge_day_ints(*hashes)
      merged = Hash.new(0)
      hashes.each do |h|
        next if h.blank?

        h.each { |date_key, value| merged[date_key] += value.to_i }
      end
      merged.sort_by { |k, _| Date.parse(k.to_s) }.to_h
    end

    def merge_day_decimals(*hashes)
      merged = Hash.new(0.to_d)
      hashes.each do |h|
        next if h.blank?

        h.each { |date_key, value| merged[date_key] += value.to_d }
      end
      merged.sort_by { |k, _| Date.parse(k.to_s) }.to_h
    end
  end
end
