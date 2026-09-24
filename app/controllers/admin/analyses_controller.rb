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
    @remboursementsBoutiqueFiltres = scopes[:remboursements_boutique_filtres]
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
    @totalRemboursementsEshop = stripe_totals.remboursements_total_eur

    @analyses_vue = Analyses::DashboardVisibility.normalize_vue(params[:vue])
    @analyses_visibility = Analyses::DashboardVisibility.new(
      filter_params,
      ca_mode: @analyses_ca_mode,
      vue: @analyses_vue
    )

    Analyses::DashboardMetrics.new(self).assign_tab!(
      @analyses_vue,
      filter_params: filter_params,
      stripe_totals: stripe_totals
    )

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
    permitted = params.permit(
      :debut, :fin, :vue,
      :filter_locvente, :filter_eshop, :filter_propart
    ).to_h.symbolize_keys

    Admin::ProduitListingFilters::ANALYSES_MULTI_FILTER_KEYS.each do |key|
      values = Admin::ProduitListingFilters.normalize_filter_values(params[key])
      permitted[key] = values if values.any?
    end

    permitted
  end

  def load_filter_collections
    @profiles_for_filter = Profile.for_analyses_charts.order(:prenom, :nom)
    @categorie_produits = CategorieProduit.order(:nom)
    @type_produits = TypeProduit.order(:nom)
    @couleurs = Couleur.order(:nom)
    @tailles = Taille.order(:nom)
    @fournisseurs = Fournisseur.order(:nom)
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
      top = stats.max_by { |r| r[:ca].to_d }
      {
        equipe_ca: stats.sum { |r| r[:ca].to_d },
        equipe_commandes: stats.sum { |r| r[:commandes].to_i },
        equipe_devis: stats.sum { |r| r[:devis].to_i },
        top_vendeur_ca: top&.dig(:ca).to_d,
        top_vendeur_profile_id: top&.dig(:profile_id)
      }
    else
      top = @synthese_top_profile
      {
        ca: @totalPrixCa,
        commandes: @nbTotal,
        articles_lignes: @nbTotalArticles,
        top_vendeur_ca: top&.dig(:ca).to_d,
        top_vendeur_profile_id: top&.dig(:profile_id)
      }
    end
  end
end
