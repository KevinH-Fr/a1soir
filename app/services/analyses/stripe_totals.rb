# frozen_string_literal: true

module Analyses
  # CA Stripe (centimes → euros) net des remboursements e-shop, éventuellement ventilé par lignes produit.
  class StripeTotals
    def initialize(datedebut:, datefin:, stripe_payments_scope:, filtered_produits: nil, product_dimension_filtered: false)
      @datedebut = datedebut
      @datefin = datefin
      @stripe_payments_scope = stripe_payments_scope
      @filtered_produits = filtered_produits
      @product_dimension_filtered = product_dimension_filtered
    end

    def total_eur(commande_ids: nil)
      return 0.to_d if commande_ids&.empty?

      if commande_ids.nil?
        return @total_eur if defined?(@total_eur)
      end

      gross = if @product_dimension_filtered
                stripe_items_eur(commande_ids: commande_ids)
              else
                scope = @stripe_payments_scope
                scope = scope.where(commande_id: commande_ids) unless commande_ids.nil?
                scope.sum(:amount).to_d / 100
              end
      result = gross - remboursements_eur(commande_ids: commande_ids)
      @total_eur = result if commande_ids.nil?
      result
    end

    # Total remboursements e-shop sur la période (montant positif).
    def remboursements_total_eur(commande_ids: nil)
      return 0.to_d if commande_ids&.empty?

      if commande_ids.nil?
        return @remboursements_total_eur if defined?(@remboursements_total_eur)

        @remboursements_total_eur = remboursements_eur
        return @remboursements_total_eur
      end

      remboursements_eur(commande_ids: commande_ids)
    end

    def grouped_by_day_eur
      @grouped_by_day_eur ||= if @product_dimension_filtered
                                grouped_stripe_items_by_day
                              else
                                @stripe_payments_scope
                                  .group("DATE(stripe_payments.created_at)")
                                  .order("DATE(stripe_payments.created_at)")
                                  .sum(:amount)
                                  .transform_values { |cents| cents.to_d / 100 }
                              end
    end

    private

    def stripe_items_scope(commande_ids: nil)
      scope = StripePaymentItem.not_refunded
                               .joins(:stripe_payment, :produit)
                               .merge(@stripe_payments_scope)
                               .merge(@filtered_produits)
      scope = scope.where(stripe_payments: { commande_id: commande_ids }) if commande_ids
      scope
    end

    def stripe_items_eur(commande_ids: nil)
      return 0.to_d if commande_ids&.empty?

      stripe_items_scope(commande_ids: commande_ids)
        .sum("stripe_payment_items.quantity * stripe_payment_items.unit_amount")
        .to_d / 100
    end

    def grouped_stripe_items_by_day
      stripe_items_scope
        .group("DATE(stripe_payments.created_at)")
        .order("DATE(stripe_payments.created_at)")
        .sum("stripe_payment_items.quantity * stripe_payment_items.unit_amount")
        .transform_values { |cents| cents.to_d / 100 }
    end

    def remboursements_eur(commande_ids: nil)
      return 0.to_d if commande_ids&.empty?

      rel = AvoirRemb.remb_only.joins(:commande).where(commandes: { eshop: true })
      if @datedebut.present? && @datefin.present?
        rel = rel.where(
          "COALESCE(avoir_rembs.custom_date, DATE(avoir_rembs.created_at)) BETWEEN ? AND ?",
          @datedebut.to_date,
          @datefin.to_date
        )
      end
      rel = rel.where(commande_id: commande_ids) if commande_ids
      # Toujours borner aux commandes du scope Stripe (évite un CA Stripe négatif
      # si un remboursement existe sans paiement paid dans la fenêtre).
      if commande_ids.nil?
        rel = rel.where(commande_id: @stripe_payments_scope.select(:commande_id))
      end
      rel.sum(:montant).to_d
    end
  end
end
