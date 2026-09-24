# frozen_string_literal: true

module Analyses
  # Agrégats KPI pour une fenêtre de dates + filtres (sans séries temporelles).
  # `metrics:` limite les clés calculées (évite p.ex. equipe_totals hors onglet équipe).
  class KpiSnapshot < ApplicationService
    ALL_METRICS = %i[
      ca commandes articles_lignes devis
      transactions stripe
      quantites ca_lignes produits
      equipe_ca equipe_commandes equipe_devis
      top_vendeur_ca
    ].freeze

    def self.call(filter_params, metrics: nil)
      new(filter_params, metrics: metrics).call
    end

    def initialize(filter_params, metrics: nil)
      @filter_params = filter_params.to_h.symbolize_keys
      @metrics = metrics&.map(&:to_sym)
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
    end

    def call
      commandes = @scopes[:commandes_filtres]
      articles = @scopes[:articles_filtres]
      sous_articles = @scopes[:sous_articles_filtres]
      paiements = @scopes[:paiements_filtres]
      result = {}

      result[:ca] = ca_total(articles, sous_articles, paiements) if need?(:ca)
      result[:commandes] = commandes.count if need?(:commandes)
      result[:devis] = devis_count if need?(:devis)
      result[:stripe] = stripe_eur if need?(:stripe)

      if need_any?(:articles_lignes, :quantites, :ca_lignes, :produits)
        line_metrics = LineMetrics.new(
          articles_scope: articles,
          stripe_items_scope: @scopes[:stripe_payment_items_filtres]
        )
        result[:articles_lignes] = line_metrics.quantites if need?(:articles_lignes)
        result[:quantites] = line_metrics.quantites if need?(:quantites)
        result[:ca_lignes] = line_metrics.ca_lignes if need?(:ca_lignes)
        result[:produits] = line_metrics.produits_count if need?(:produits)
      end

      if need?(:transactions)
        result[:transactions] = transaction_totals(articles, sous_articles)[:total]
      end

      if need_any?(:equipe_ca, :equipe_commandes, :equipe_devis)
        totals = equipe_totals
        result[:equipe_ca] = totals[:ca] if need?(:equipe_ca)
        result[:equipe_commandes] = totals[:commandes] if need?(:equipe_commandes)
        result[:equipe_devis] = totals[:devis] if need?(:equipe_devis)
      end

      result[:top_vendeur_ca] = profile_ca(@filter_params[:top_vendeur_profile_id]) if need?(:top_vendeur_ca)

      result
    end

    private

    def need?(key)
      needed_metrics.include?(key)
    end

    def need_any?(*keys)
      keys.any? { |key| need?(key) }
    end

    def needed_metrics
      @needed_metrics ||= (@metrics.presence || ALL_METRICS)
    end

    def stripe_eur
      @stripe_eur ||= @stripe_totals.total_eur
    end

    def ca_total(articles, sous_articles, paiements)
      if @ca_mode == :lignes
        boutique = articles.where(commandes: { eshop: [false, nil] }).sum(:prix).to_d +
                   sous_articles.joins(article: :commande).where(commandes: { eshop: [false, nil] }).sum(:prix).to_d
        boutique + stripe_eur
      else
        boutique = paiements.only_prix
                            .where(moyen: ["carte bleue", "espèces", "chèque", "virement"])
                            .sum(:montant).to_d
        boutique - boutique_remboursements_total + stripe_eur
      end
    end

    def boutique_remboursements_total
      @boutique_remboursements_total ||= (@scopes[:remboursements_boutique_filtres] || AvoirRemb.none).sum(:montant).to_d
    end

    def boutique_remboursements_for_profile(profile_id)
      (@scopes[:remboursements_boutique_filtres] || AvoirRemb.none)
        .merge(Commande.where(profile_id: profile_id))
        .sum(:montant).to_d
    end

    def transaction_totals(articles, sous_articles)
      loc = articles.location_only.sum(:prix).to_d + sous_articles.location_only.sum(:prix).to_d
      articles_vente_hors_eshop = articles.where(commandes: { eshop: [false, nil] }).vente_only.sum(:prix).to_d
      sous_vente_hors_eshop = sous_articles.joins(article: :commande).merge(Commande.hors_devis).where(commandes: { eshop: [false, nil] }).vente_only.sum(:prix).to_d
      vente = articles_vente_hors_eshop + sous_vente_hors_eshop + stripe_eur
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
                         paiements.only_prix.joins(:commande).where(commandes: { profile_id: profile.id }).sum(:montant).to_d -
                           boutique_remboursements_for_profile(profile.id)
                       end
        stripe_ids = @scopes[:stripe_payments_paid_filtres]
                       .where(commande_id: Commande.where(profile_id: profile.id).select(:id))
                       .distinct.pluck(:commande_id)
        ca += ca_paiements + @stripe_totals.total_eur(commande_ids: stripe_ids)
      end

      { ca: ca, commandes: commandes, devis: devis }
    end

    # CA d'un vendeur (même logique que l'agrégat équipe, un seul profil).
    def profile_ca(profile_id)
      return 0.to_d if profile_id.blank?

      ids = @scopes[:commandes_filtres].where(profile_id: profile_id).pluck(:id)

      ca_paiements = if @ca_mode == :lignes
                       return 0.to_d if ids.blank?

                       @scopes[:articles_filtres]
                         .where(commande_id: ids)
                         .joins(:commande)
                         .where(commandes: { eshop: [false, nil] })
                         .sum(:prix).to_d +
                       @scopes[:sous_articles_filtres]
                         .joins(article: :commande)
                         .where(commandes: { id: ids, eshop: [false, nil] })
                         .sum(:prix).to_d
                     else
                       @scopes[:paiements_filtres].only_prix.joins(:commande)
                                                  .where(commandes: { profile_id: profile_id })
                                                  .sum(:montant).to_d -
                         boutique_remboursements_for_profile(profile_id)
                     end

      stripe_ids = @scopes[:stripe_payments_paid_filtres]
                     .where(commande_id: Commande.where(profile_id: profile_id).select(:id))
                     .distinct.pluck(:commande_id)
      ca_paiements + @stripe_totals.total_eur(commande_ids: stripe_ids)
    end
  end
end
