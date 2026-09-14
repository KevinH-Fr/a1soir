# frozen_string_literal: true

module Analyses
  # Agrégats KPI pour une fenêtre de dates + filtres (sans séries temporelles).
  class KpiSnapshot < ApplicationService
    def initialize(filter_params)
      @filter_params = filter_params.to_h.symbolize_keys
      @scopes = DashboardScopes.call(@filter_params)
      @datedebut = @scopes[:datedebut]
      @datefin = @scopes[:datefin]
      @product_dimension_filtered = @scopes[:product_dimension_filtered]
      @ca_mode = @product_dimension_filtered ? :lignes : :paiements
      @stripe_totals = StripeTotals.new(
        datedebut: @datedebut,
        datefin: @datefin,
        stripe_payments_scope: @scopes[:stripe_payments_paid_filtres],
        filtered_produits: @scopes[:filtered_produits],
        product_dimension_filtered: @product_dimension_filtered
      )
      @stripe_eur = @stripe_totals.total_eur
    end

    def call
      commandes = @scopes[:commandes_filtres]
      articles = @scopes[:articles_filtres]
      sous_articles = @scopes[:sous_articles_filtres]
      paiements = @scopes[:paiements_filtres]
      line_metrics = LineMetrics.new(
        articles_scope: articles,
        stripe_items_scope: @scopes[:stripe_payment_items_filtres]
      )

      total_prix_ca = ca_total(articles, sous_articles, paiements)
      transactions = transaction_totals(articles, sous_articles)

      {
        ca: total_prix_ca,
        commandes: commandes.count,
        articles_lignes: line_metrics.lignes_count,
        devis: devis_count,
        transactions: transactions[:total],
        stripe: @stripe_eur,
        quantites: line_metrics.quantites,
        ca_lignes: line_metrics.ca_lignes,
        produits: line_metrics.produits_count,
        equipe_ca: equipe_totals[:ca],
        equipe_commandes: equipe_totals[:commandes],
        equipe_devis: equipe_totals[:devis]
      }
    end

    private

    def ca_total(articles, sous_articles, paiements)
      if @ca_mode == :lignes
        boutique = articles.where(commandes: { eshop: [false, nil] }).sum(:prix).to_d +
                   sous_articles.joins(article: :commande).where(commandes: { eshop: [false, nil] }).sum(:prix).to_d
        boutique + @stripe_eur
      else
        boutique = paiements.only_prix.only_cb.sum(:montant).to_d +
                   paiements.only_prix.only_espece.sum(:montant).to_d +
                   paiements.only_prix.only_cheque.sum(:montant).to_d +
                   paiements.only_prix.only_virement.sum(:montant).to_d
        boutique + @stripe_eur
      end
    end

    def transaction_totals(articles, sous_articles)
      loc = articles.location_only.sum(:prix).to_d + sous_articles.location_only.sum(:prix).to_d
      articles_vente_hors_eshop = articles.where(commandes: { eshop: [false, nil] }).vente_only.sum(:prix).to_d
      sous_vente_hors_eshop = sous_articles.joins(article: :commande).merge(Commande.hors_devis).where(commandes: { eshop: [false, nil] }).vente_only.sum(:prix).to_d
      vente = articles_vente_hors_eshop + sous_vente_hors_eshop + @stripe_eur
      { total: loc + vente, loc: loc, vente: vente }
    end

    def devis_count
      scope = Commande.est_devis
      if @datedebut.present? && @datefin.present?
        scope = scope.filtredatedebut(@datedebut).filtredatefin(@datefin)
      end
      scope.count
    end

    def equipe_totals
      profiles = Profile.for_analyses_charts.order(:prenom, :nom)
      if @filter_params[:filter_profile].present?
        profiles = profiles.where(id: @filter_params[:filter_profile])
      end

      commandes_scope = @scopes[:commandes_filtres]
      paiements = @scopes[:paiements_filtres]
      articles = @scopes[:articles_filtres]
      sous_articles = @scopes[:sous_articles_filtres]

      devis_scope = Commande.est_devis
      if @datedebut.present? && @datefin.present?
        devis_scope = devis_scope.filtredatedebut(@datedebut).filtredatefin(@datefin)
      end

      ca = 0.to_d
      commandes = 0
      devis = 0

      profiles.find_each do |profile|
        profile_commandes = commandes_scope.where(profile_id: profile.id)
        ids = profile_commandes.pluck(:id)
        commandes += profile_commandes.count
        devis += devis_scope.where(profile_id: profile.id).count

        ca_paiements = if @ca_mode == :lignes
                         articles.where(commande_id: ids).joins(:commande).where(commandes: { eshop: [false, nil] }).sum(:prix).to_d +
                           sous_articles.joins(article: :commande).where(commandes: { id: ids, eshop: [false, nil] }).sum(:prix).to_d
                       else
                         paiements.only_prix.where(commande_id: ids).sum(:montant).to_d
                       end
        ca += ca_paiements + @stripe_totals.total_eur(commande_ids: ids)
      end

      { ca: ca, commandes: commandes, devis: devis }
    end
  end
end
