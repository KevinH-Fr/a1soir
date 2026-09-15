# frozen_string_literal: true

# Dashboard admin Analyses : filtres, onglets (synthèse / CA / catalogue / équipe)
# et délégation des calculs aux services Analyses::*.
class Admin::AnalysesController < Admin::ApplicationController
  include Admin::ProduitListingFilters

  before_action :redirect_to_default_period, only: :index

  def index
    filter_params = analyses_filter_params
    scopes = Analyses::DashboardScopes.call(filter_params)

    datedebut = scopes[:datedebut]
    datefin = scopes[:datefin]
    @datedebut = datedebut
    @datefin = datefin

    @commandesFiltres = scopes[:commandes_filtres]
    @articlesFiltres = scopes[:articles_filtres]
    @sousArticlesFiltres = scopes[:sous_articles_filtres]
    @paiementsFiltres = scopes[:paiements_filtres]
    @stripePaymentsPaidFiltres = scopes[:stripe_payments_paid_filtres]
    @stripePaymentItemsFiltres = scopes[:stripe_payment_items_filtres]
    @product_dimension_filtered = scopes[:product_dimension_filtered]
    @analyses_ca_mode = @product_dimension_filtered ? :lignes : :paiements
    @line_metrics = Analyses::LineMetrics.new(
      articles_scope: @articlesFiltres,
      stripe_items_scope: @stripePaymentItemsFiltres
    )

    stripe_totals = Analyses::StripeTotals.new(
      datedebut: datedebut,
      datefin: datefin,
      stripe_payments_scope: @stripePaymentsPaidFiltres,
      filtered_produits: scopes[:filtered_produits],
      product_dimension_filtered: @product_dimension_filtered
    )
    @total_stripe_eur = stripe_totals.total_eur

    @analyses_vue = Analyses::DashboardVisibility.normalize_vue(params[:vue])
    @analyses_visibility = Analyses::DashboardVisibility.new(
      filter_params,
      ca_mode: @analyses_ca_mode,
      vue: @analyses_vue
    )

    Analyses::DashboardPresenter.new(
      self,
      scopes: scopes,
      filter_params: filter_params,
      stripe_totals: stripe_totals
    ).call(vue: @analyses_vue)

    kpi_trends = Analyses::KpiTrends.call(
      filter_params: filter_params,
      vue: @analyses_vue,
      current: current_kpi_values_for_trends(@analyses_vue)
    )
    @analyses_kpi_trends = kpi_trends[:trends]
    @analyses_kpi_trend_period_label = kpi_trends[:period_label]

    load_filter_collections

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  private

  def redirect_to_default_period
    return if params[:debut].present? && params[:fin].present?

    debut, fin = helpers.default_analyses_period
    redirect_to admin_analyses_index_path(request.query_parameters.symbolize_keys.merge(debut: debut, fin: fin))
  end

  def analyses_filter_params
    params.permit(
      :debut, :fin, :vue,
      :filter_profile, :filter_locvente, :filter_eshop,
      *Admin::ProduitListingFilters::ADMIN_PRODUIT_FILTER_KEYS
    )
  end

  def assign_commande_metrics
    @nbTotal = @commandesFiltres.count
    @nbRetire = @commandesFiltres.retire.count
    @nbNonRetire = @commandesFiltres.non_retire.count
    @nbRendu = @commandesFiltres.rendu.count
    @nbDevisPeriode = devis_dans_periode(@datedebut, @datefin).count

    grouped_by_date = @commandesFiltres.group("DATE(created_at)").order("DATE(commandes.created_at)").count("created_at")
    @groupedByDate = grouped_by_date.transform_keys do |date|
      I18n.l(Date.parse(date.to_s), format: "%d/%m/%Y")
    end
  end

  def assign_article_metrics
    @nbTotalArticles = @line_metrics.lignes_count
    @nbLoc = @line_metrics.loc_lignes_count
    @nbVente = @line_metrics.vente_lignes_count

    @groupedByDateArticles = @line_metrics.quantites_by_day.transform_keys do |date|
      I18n.l(Date.parse(date.to_s), format: "%d/%m/%Y")
    end
  end

  def assign_transaction_metrics(stripe_totals, datedebut, datefin)
    @totalTransactionsLoc = @articlesFiltres.location_only.sum(:prix).to_d + @sousArticlesFiltres.location_only.sum(:prix).to_d
    articles_vente_hors_eshop = @articlesFiltres.where(commandes: { eshop: [false, nil] }).vente_only.sum(:prix).to_d
    sous_vente_hors_eshop = @sousArticlesFiltres.joins(article: :commande).merge(Commande.hors_devis).where(commandes: { eshop: [false, nil] }).vente_only.sum(:prix).to_d
    @totalTransactionsVente = articles_vente_hors_eshop + sous_vente_hors_eshop + @total_stripe_eur
    @totalTransactions = @totalTransactionsLoc + @totalTransactionsVente

    articles_timeline = @articlesFiltres.where(commandes: { eshop: [false, nil] })
    grouped_articles_jour = articles_timeline.group("DATE(articles.created_at)").order("DATE(articles.created_at)").sum("total")
    @groupedByDateTransactions = merge_grouped_by_day(
      grouped_articles_jour,
      stripe_totals.grouped_by_day_eur,
      eshop_remboursements_by_day_neg(datedebut, datefin)
    )
  end

  def assign_ca_metrics(stripe_totals, datedebut, datefin)
    if @analyses_ca_mode == :lignes
      assign_ca_metrics_from_lines(stripe_totals, datedebut, datefin)
    else
      assign_ca_metrics_from_paiements(stripe_totals, datedebut, datefin)
    end
  end

  def assign_ca_metrics_from_paiements(stripe_totals, datedebut, datefin)
    by_moyen = @paiementsFiltres.only_prix.group(:moyen).sum(:montant)
    @totalPrixCaCb = by_moyen.fetch("carte bleue", 0).to_d
    @totalPrixCaEspeces = by_moyen.fetch("espèces", 0).to_d
    @totalPrixCaCheque = by_moyen.fetch("chèque", 0).to_d
    @totalPrixCaVirement = by_moyen.fetch("virement", 0).to_d
    @totalPrixCaStripe = @total_stripe_eur
    @totalPrixCaBoutique = @totalPrixCaCb + @totalPrixCaEspeces + @totalPrixCaCheque + @totalPrixCaVirement
    @totalPrixCa = @totalPrixCaBoutique + @totalPrixCaStripe
    @totalCa = @paiementsFiltres.sum(:montant).to_d + @total_stripe_eur

    grouped_by_date_ca_paiements = @paiementsFiltres.group("DATE(created_at)").order("DATE(paiement_recus.created_at)").sum(:montant)
    @groupedByDateCa = merge_grouped_by_day(
      grouped_by_date_ca_paiements,
      stripe_totals.grouped_by_day_eur,
      eshop_remboursements_by_day_neg(datedebut, datefin)
    )
  end

  def assign_ca_metrics_from_lines(stripe_totals, datedebut, datefin)
    boutique_lines = @articlesFiltres.where(commandes: { eshop: [false, nil] }).sum(:prix).to_d +
                     @sousArticlesFiltres.joins(article: :commande).where(commandes: { eshop: [false, nil] }).sum(:prix).to_d
    @totalPrixCaCb = 0.to_d
    @totalPrixCaEspeces = 0.to_d
    @totalPrixCaCheque = 0.to_d
    @totalPrixCaVirement = 0.to_d
    @totalPrixCaStripe = @total_stripe_eur
    @totalPrixCaBoutique = boutique_lines
    @totalPrixCa = boutique_lines + @total_stripe_eur
    @totalCa = @totalPrixCa

    grouped_articles_jour = @articlesFiltres.where(commandes: { eshop: [false, nil] }).group("DATE(articles.created_at)").order("DATE(articles.created_at)").sum("total")
    @groupedByDateCa = merge_grouped_by_day(
      grouped_articles_jour,
      stripe_totals.grouped_by_day_eur,
      eshop_remboursements_by_day_neg(datedebut, datefin)
    )
  end

  def assign_profile_stats(datedebut, datefin, stripe_totals, filter_params)
    profiles = Profile.for_analyses_charts.order(:prenom, :nom)
    profiles = profiles.where(id: filter_params[:filter_profile]) if filter_params[:filter_profile].present?

    commandes_devis = if datedebut.present? && datefin.present?
                        Commande.est_devis.filtredatedebut(datedebut).filtredatefin(datefin)
                      else
                        Commande.est_devis.all
                      end

    @stats_par_profile = profiles.map.with_index do |profile, index|
      row = profile_kpi_row(profile, stripe_totals)
      row.merge(
        devis: commandes_devis.where(profile_id: profile.id).count,
        couleur: Analyses::ChartPayloads.equipe_pastel_color(index),
        ca_by_day: profile_ca_by_day(row[:commande_ids], datedebut, datefin)
      ).except(:commande_ids)
    end
  end

  # Synthèse : top vendeur uniquement (pas de séries journalières).
  def assign_synthese_top_profile(_datedebut, _datefin, stripe_totals, filter_params)
    profiles = Profile.for_analyses_charts.order(:prenom, :nom)
    profiles = profiles.where(id: filter_params[:filter_profile]) if filter_params[:filter_profile].present?

    rows = profiles.map { |profile| profile_kpi_row(profile, stripe_totals) }
    top = rows.max_by { |r| r[:ca].to_d }
    @synthese_top_profile =
      if top
        top.merge(articles: profile_articles_lignes_count(top[:commande_ids])).except(:commande_ids)
      end
  end

  def profile_kpi_row(profile, stripe_totals)
    commandes = @commandesFiltres.where(profile_id: profile.id)
    commandes_ids = commandes.pluck(:id)
    ca_paiements = if @analyses_ca_mode == :lignes
                     ligne_ca_for_commandes(commandes_ids)
                   else
                     @paiementsFiltres.only_prix.where(commande_id: commandes_ids).sum(:montant).to_d
                   end
    ca = ca_paiements + stripe_totals.total_eur(commande_ids: commandes_ids)
    label = profile.full_name.presence || profile.prenom.presence || "Profil ##{profile.id}"

    {
      profile: label,
      profile_id: profile.id,
      commandes: commandes.count,
      ca: ca,
      commande_ids: commandes_ids
    }
  end

  def profile_articles_lignes_count(commandes_ids)
    return 0 if commandes_ids.blank?

    stripe_scope =
      if @stripePaymentItemsFiltres.nil?
        StripePaymentItem.none
      else
        @stripePaymentItemsFiltres.joins(:stripe_payment).where(stripe_payments: { commande_id: commandes_ids })
      end

    Analyses::LineMetrics.new(
      articles_scope: @articlesFiltres.where(commande_id: commandes_ids),
      stripe_items_scope: stripe_scope
    ).lignes_count
  end

  def profile_ca_by_day(commandes_ids, datedebut, datefin)
    return {} if commandes_ids.blank?

    boutique =
      if @analyses_ca_mode == :lignes
        @articlesFiltres
          .where(commande_id: commandes_ids)
          .joins(:commande)
          .where(commandes: { eshop: [false, nil] })
          .group("DATE(articles.created_at)")
          .sum(:prix)
      else
        @paiementsFiltres.only_prix
          .where(commande_id: commandes_ids)
          .group("DATE(paiement_recus.created_at)")
          .sum(:montant)
      end

    stripe = @stripePaymentsPaidFiltres
               .where(commande_id: commandes_ids)
               .group("DATE(stripe_payments.created_at)")
               .sum(:amount)
               .transform_values { |cents| cents.to_d / 100 }

    remb = eshop_remboursements_scope(
             datedebut,
             datefin,
             product_dimension_filtered: false
           )
             .where(commande_id: commandes_ids)
             .group("COALESCE(avoir_rembs.custom_date, DATE(avoir_rembs.created_at))")
             .sum(:montant)
             .transform_values { |montant| -montant.to_d }

    merge_grouped_by_day(boutique, stripe, remb)
  end

  def ligne_ca_for_commandes(commandes_ids)
    articles = @articlesFiltres.where(commande_id: commandes_ids).joins(:commande).where(commandes: { eshop: [false, nil] }).sum(:prix).to_d
    sous = @sousArticlesFiltres.joins(article: :commande).where(commandes: { id: commandes_ids, eshop: [false, nil] }).sum(:prix).to_d
    articles + sous
  end

  def assign_catalog_stats
    stats = Analyses::CatalogStats.call(
      @articlesFiltres,
      stripe_items_scope: @stripePaymentItemsFiltres
    )
    @catalog_top_products = stats[:top_products]
    @catalog_by_type = stats[:by_type]
    @catalog_by_categorie = stats[:by_categorie]
    @catalog_categorie_notice = stats[:categorie_attribution_notice]
  end

  def load_filter_collections
    @profiles_for_filter = Profile.for_analyses_charts.order(:prenom, :nom)
    @categorie_produits = CategorieProduit.order(:nom)
    @type_produits = TypeProduit.order(:nom)
    @couleurs = Couleur.order(:nom)
    @tailles = Taille.order(:nom)
  end

  def eshop_remboursements_scope(datedebut, datefin, product_dimension_filtered: false, stripe_scope: nil)
    rel = AvoirRemb.remb_only.joins(:commande).where(commandes: { eshop: true })
    if datedebut.present? && datefin.present?
      rel = rel.where(
        "COALESCE(avoir_rembs.custom_date, DATE(avoir_rembs.created_at)) BETWEEN ? AND ?",
        datedebut.to_date,
        datefin.to_date
      )
    end
    if product_dimension_filtered && stripe_scope
      rel = rel.where(commande_id: stripe_scope.select(:commande_id))
    end
    rel
  end

  def eshop_remboursements_grouped_by_day(datedebut, datefin, product_dimension_filtered: false, stripe_scope: nil)
    eshop_remboursements_scope(datedebut, datefin, product_dimension_filtered: product_dimension_filtered, stripe_scope: stripe_scope)
      .group("COALESCE(avoir_rembs.custom_date, DATE(avoir_rembs.created_at))")
      .sum(:montant)
  end

  # Mémo requête : onglet CA appelle CA + transactions avec les mêmes bornes.
  def eshop_remboursements_by_day_neg(datedebut, datefin)
    @eshop_remboursements_by_day_neg ||= eshop_remboursements_grouped_by_day(
      datedebut,
      datefin,
      product_dimension_filtered: @product_dimension_filtered,
      stripe_scope: @stripePaymentsPaidFiltres
    ).transform_values { |montant| -montant.to_d }
  end

  # Réutilise les ivars de l'onglet pour éviter un 2e KpiSnapshot sur la période courante.
  def current_kpi_values_for_trends(vue)
    case vue
    when "ca"
      {
        ca: @totalPrixCa,
        transactions: @totalTransactions,
        commandes: @nbTotal,
        stripe: @totalPrixCaStripe
      }
    when "catalogue"
      {
        quantites: @line_metrics.quantites,
        ca_lignes: @line_metrics.ca_lignes,
        produits: @line_metrics.produits_count
      }
    when "equipe"
      stats = @stats_par_profile || []
      {
        equipe_ca: stats.sum { |r| r[:ca].to_d },
        equipe_commandes: stats.sum { |r| r[:commandes].to_i },
        equipe_devis: stats.sum { |r| r[:devis].to_i }
      }
    else
      {
        ca: @totalPrixCa,
        commandes: @nbTotal,
        articles_lignes: @nbTotalArticles
      }
    end
  end

  def devis_dans_periode(datedebut, datefin)
    scope = Commande.est_devis
    if datedebut.present? && datefin.present?
      scope = scope.filtredatedebut(datedebut).filtredatefin(datefin)
    end
    scope
  end

  def merge_grouped_by_day(*hashes)
    merged = Hash.new(0.to_d)
    hashes.each do |h|
      next if h.blank?

      h.each do |date_key, amount|
        label = I18n.l(Date.parse(date_key.to_s), format: "%d/%m/%Y")
        merged[label] += amount.to_d
      end
    end
    merged.sort_by { |k, _| Date.strptime(k, "%d/%m/%Y") }.to_h
  end
end
