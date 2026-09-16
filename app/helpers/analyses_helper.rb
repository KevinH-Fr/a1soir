# Helpers UI du dashboard Analyses : onglets, URLs de filtres, rendu des sections graphiques.
module AnalysesHelper
  ANALYSES_FILTER_KEYS = (
    Admin::ProduitListingFilters::ADMIN_PRODUIT_FILTER_KEYS +
    %i[filter_profile filter_locvente filter_eshop filter_propart debut fin vue]
  ).freeze

  ANALYSES_TABS = [
    { vue: "synthese", label: "Synthèse", icon: "graph-up-arrow", tone: "synthese",
      description: "Vue d'ensemble de l'activité" },
    { vue: "ca", label: "Chiffre d'affaires", icon: "cash-stack", tone: "ca",
      description: "Encaissements et transactions" },
    { vue: "catalogue", label: "Catalogue", icon: "bag", tone: "catalogue",
      description: "Produits et répartitions" },
    { vue: "equipe", label: "Équipe", icon: "people-fill", tone: "equipe",
      description: "Performance par vendeur" }
  ].freeze

  def analyses_chart_box_classes(*extras)
    class_names("w-100 mx-auto analyses-chart-box", *extras)
  end

  def analyses_equipe_bars_height_rem(profile_count)
    n = [profile_count.to_i, 1].max
    # ~2.1rem par barre + marge axes ; plafonné pour le responsive.
    [[10 + (n * 2.1), 12].max, 26].min.round(1)
  end

  def render_analyses_chart(key, chart_id: nil, aria_label: nil, extra_class: nil, box_style: nil)
    config = analyses_chart_config(key)
    return "" if config.blank?

    # Métadonnées UI (pas pour Chart.js) — texte central HTML.
    center_lines = Array(config.delete(:_centerText)).presence

    render(
      partial: "admin/analyses/chart_canvas",
      locals: {
        chart_id: chart_id || "analyses-chart-#{key}",
        config: config,
        aria_label: aria_label,
        extra_class: extra_class,
        box_style: box_style,
        center_lines: center_lines
      }
    )
  end

  def analyses_donut_amount_label(amount)
    number_with_delimiter(amount.to_d.round, delimiter: " ")
  end

  def analyses_donut_ht_label(ttc_amount)
    analyses_donut_amount_label(montant_ht_depuis_ttc(ttc_amount))
  end

  def analyses_filter_params(exclude: nil, include_dates: true)
    keys = ANALYSES_FILTER_KEYS.dup
    keys -= %i[debut fin] unless include_dates
    keys -= [exclude.to_sym] if exclude.present?
    request.query_parameters.symbolize_keys.slice(*keys)
  end

  def analyses_active_filters_count
    filter_keys = Admin::ProduitListingFilters::ADMIN_PRODUIT_FILTER_KEYS +
                  %i[filter_profile filter_locvente filter_eshop filter_propart]
    filter_keys.count { |k| params[k].present? }
  end

  def analyses_ca_mode_lignes?
    @analyses_ca_mode == :lignes
  end

  def analyses_vue
    @analyses_vue.presence || Analyses::DashboardVisibility.normalize_vue(params[:vue])
  end

  def analyses_tabs
    ANALYSES_TABS
  end

  def analyses_vue_meta
    ANALYSES_TABS.find { |tab| tab[:vue] == analyses_vue } || ANALYSES_TABS.first
  end

  def analyses_visibility
    @analyses_visibility
  end

  def analyses_visibility_show?(widget)
    analyses_visibility&.show?(widget)
  end

  def analyses_tab_path(vue, **extra)
    base = analyses_filter_params(include_dates: true).merge(vue: vue, **extra)
    base.delete(:filter_profile) if vue.to_s == "equipe"
    admin_analyses_index_path(base)
  end

  def analyses_path_without_filter(filter_key)
    analyses_tab_path(analyses_vue, filter_key => nil)
  end

  def analyses_chart_config(key)
    Analyses::ChartPayloads.new(self).build(key)
  end

  def default_analyses_period
    today = Date.current
    [today - 29, today]
  end

  def analyses_chart_heading(title, meta: nil, extra_class: nil)
    tag.div(class: class_names("analyses-chart-heading", extra_class)) do
      parts = [tag.p(title, class: "analyses-chart-heading__title mb-0")]
      if meta.present?
        parts << tag.p(meta, class: "analyses-chart-heading__meta mb-0")
      end
      safe_join(parts)
    end
  end

  # Card légère autour d'un chart (sans titre de section global).
  def analyses_chart_card(extra_class: nil, &block)
    tag.div(class: class_names("analyses-chart-card", extra_class), &block)
  end

  def analyses_info_alert(message, extra_class: nil)
    tag.div(class: class_names("alert alert-info py-1 px-2 mb-2 small text-dark", extra_class), role: "status") do
      safe_join([
        tag.i(class: "bi bi-info-circle me-1", aria: { hidden: true }),
        message
      ])
    end
  end

  def analyses_filter_dropdown(label:, icon:, param_key:, collection:, model:, all_label:)
    filter_base = analyses_filter_params(include_dates: true).merge(vue: analyses_vue)
    content_tag(:div, class: "min-w-0 analyses-filter-field__dropdown") do
      filter_dropdown(
        label: label,
        icon: icon,
        param_key: param_key,
        collection: collection,
        model: model,
        current_params: filter_base.except(param_key),
        all_label: all_label,
        columns: 2,
        id_suffix: "analyses",
        always_show_label: true,
        link_data: { turbo_stream: true }
      )
    end
  end

  def analyses_filter_toggle_group(aria_label:, param_key:, options:)
    tag.div(class: "btn-group btn-group-sm w-100", role: "group", aria: { label: aria_label }) do
      safe_join(
        options.map do |label, value|
          active = params[param_key].to_s == value.to_s || (value.nil? && params[param_key].blank?)
          link_to label,
                  admin_analyses_index_path(
                    analyses_period_params(debut: params[:debut], fin: params[:fin]).merge(param_key => value)
                  ),
                  class: class_names(
                    "btn flex-fill",
                    active ? "btn-secondary" : "btn-outline-secondary"
                  ),
                  data: { turbo_stream: true }
        end
      )
    end
  end

  def analyses_active_filter_chips
    chips = []
    if params[:filter_profile].present?
      profile = Profile.find_by(id: params[:filter_profile])
      label = profile&.full_name.presence || profile&.prenom || "Profil ##{params[:filter_profile]}"
      chips << { key: :filter_profile, label: "Vendeur", value: label }
    end
    if params[:filter_eshop].present?
      value = { "true" => "E-shop", "false" => "Boutique" }[params[:filter_eshop].to_s] || params[:filter_eshop]
      chips << { key: :filter_eshop, label: "Canal", value: value }
    end
    if params[:filter_propart].present?
      value = {
        "particulier" => "Particulier",
        "professionnel" => "Professionnel"
      }[params[:filter_propart].to_s] || params[:filter_propart]
      chips << { key: :filter_propart, label: "Client", value: value }
    end
    if params[:filter_locvente].present?
      chips << { key: :filter_locvente, label: "Mode", value: params[:filter_locvente].to_s.capitalize }
    end
    if params[:filter_type_produit].present?
      type = TypeProduit.find_by(id: params[:filter_type_produit])
      chips << { key: :filter_type_produit, label: "Type", value: type&.nom || params[:filter_type_produit] }
    end
    if params[:filter_categorie].present?
      cat = CategorieProduit.find_by(id: params[:filter_categorie])
      chips << { key: :filter_categorie, label: "Catégorie", value: cat&.nom || params[:filter_categorie] }
    end
    if params[:filter_fournisseur].present?
      fournisseur = Fournisseur.find_by(id: params[:filter_fournisseur])
      chips << {
        key: :filter_fournisseur,
        label: "Fournisseur",
        value: params[:filter_fournisseur].to_s == "na" ? "NA" : (fournisseur&.nom || params[:filter_fournisseur])
      }
    end
    if params[:filter_couleur].present?
      couleur = Couleur.find_by(id: params[:filter_couleur])
      chips << { key: :filter_couleur, label: "Couleur", value: couleur&.nom || params[:filter_couleur] }
    end
    if params[:filter_taille].present?
      taille = Taille.find_by(id: params[:filter_taille])
      chips << { key: :filter_taille, label: "Taille", value: taille&.nom || params[:filter_taille] }
    end
    chips
  end

  def render_analyses_kpi_section
    partial = case analyses_vue
              when "ca" then "kpi_summary_ca"
              when "catalogue" then "kpi_summary_catalogue"
              when "equipe" then "kpi_summary_equipe"
              else "kpi_summary"
              end
    content_tag(:div, class: "analyses-tone analyses-tone--#{analyses_vue_meta[:tone]}") do
      safe_join([
        analyses_kpi_comparison_caption,
        render("admin/analyses/#{partial}")
      ].compact)
    end
  end

  def analyses_kpi_comparison_caption
    label = @analyses_kpi_trend_period_label
    return if label.blank?

    content_tag(:div, class: "d-flex justify-content-end mb-2") do
      content_tag(
        :span,
        "Évolution #{label}",
        class: "badge rounded-pill text-bg-light border text-body-secondary fw-normal analyses-kpi-comparison"
      )
    end
  end

  def analyses_catalog_kpi_quantite
    analyses_line_metrics.quantites
  end

  def analyses_catalog_kpi_ca_lignes
    analyses_line_metrics.ca_lignes
  end

  def analyses_catalog_kpi_produits_count
    analyses_line_metrics.produits_count
  end

  def analyses_line_metrics
    @line_metrics ||= Analyses::LineMetrics.new(
      articles_scope: @articlesFiltres,
      stripe_items_scope: @stripePaymentItemsFiltres || StripePaymentItem.none
    )
  end

  def analyses_catalog_top_product_label
    top = @catalog_top_products&.first
    return "—" unless top

    name = top[:produit]&.nom.presence || "Produit ##{top[:produit_id]}"
    truncate(name, length: 28)
  end

  # Part des quantités concentrée sur le top 3 (nil si pas de volume).
  def analyses_catalog_top3_share_pct
    total = analyses_catalog_kpi_quantite.to_i
    return nil if total.zero?

    top_qty = (@catalog_top_products || []).first(3).sum { |r| r[:quantite].to_i }
    ((top_qty * 100.0) / total).round
  end

  def analyses_equipe_kpi_totals
    stats = @stats_par_profile || []
    {
      ca: stats.sum { |r| r[:ca].to_d },
      commandes: stats.sum { |r| r[:commandes].to_i },
      devis: stats.sum { |r| r[:devis].to_i },
      vendeurs: stats.size
    }
  end

  def analyses_equipe_top_ca_row
    (@stats_par_profile || []).max_by { |r| r[:ca].to_d }
  end

  def analyses_ca_panier_moyen
    return nil if @nbTotal.blank? || @nbTotal.to_i.zero?

    (@totalPrixCa.to_d / @nbTotal.to_d).round(2)
  end

  # Hints CA boutique / Stripe partagés (synthèse + onglet CA).
  def analyses_ca_channel_hints
    remb = analyses_remboursements_eshop

    if analyses_ca_mode_lignes?
      hint2 = remb.positive? ? "Remb. e-shop #{analyses_donut_amount_label(remb)} €" : nil
      return { hint: "Montants des articles", hint2: hint2 }
    end

    ca_total = @totalPrixCa.to_d
    boutique_pct = ca_total.positive? ? ((@totalPrixCaBoutique.to_d / ca_total) * 100).round : nil
    stripe_pct = ca_total.positive? ? ((@totalPrixCaStripe.to_d / ca_total) * 100).round : nil

    hint2 = "E-shop #{analyses_donut_amount_label(@totalPrixCaStripe)} €#{stripe_pct ? " · #{stripe_pct} %" : ""}"
    hint2 = "#{hint2} · remb. #{analyses_donut_amount_label(remb)} €" if remb.positive?

    {
      hint: "Boutique #{analyses_donut_amount_label(@totalPrixCaBoutique)} €#{boutique_pct ? " · #{boutique_pct} %" : ""}",
      hint2: hint2
    }
  end

  def analyses_remboursements_eshop
    @totalRemboursementsEshop.to_d
  end

  # Lignes articles (boutique + Stripe) / commande — nil si aucune commande.
  def analyses_articles_par_commande
    return nil if @nbTotal.blank? || @nbTotal.to_i.zero?

    articles = @nbTotalArticles
    articles = analyses_line_metrics.lignes_count if articles.nil?
    (articles.to_d / @nbTotal.to_d).round(1)
  end

  def analyses_kpi_trend(metric_key)
    @analyses_kpi_trends&.dig(metric_key.to_sym)
  end

  def render_analyses_kpi_trend(metric_key)
    trend = analyses_kpi_trend(metric_key)
    return "" if trend.blank?

    render partial: "admin/analyses/kpi_trend",
           locals: {
             trend: trend,
             value_label: (metric_key.to_sym == :top_vendeur_ca ? "CA" : nil)
           }
  end

  def analyses_period_selected_range
    [parse_date(params[:debut]), parse_date(params[:fin])]
  end

  def analyses_period_preset_label
    selected = analyses_period_selected_range
    return "Période" if selected.any?(&:nil?)

    match = quick_period_definitions.find { |_label, range| range == selected }
    return match.first if match

    "Personnalisée"
  end

  def analyses_period_range_text
    debut, fin = analyses_period_selected_range
    return nil if debut.nil? || fin.nil?

    if debut == fin
      debut.strftime("%d/%m/%Y")
    else
      "#{debut.strftime("%d/%m/%Y")} – #{fin.strftime("%d/%m/%Y")}"
    end
  end

  def analyses_clear_filters_path
    # Ne garder que la vue et la période — analyses_period_params reprendrait
    # autrement tous les filtres actifs (bug « Effacer tout »).
    admin_analyses_index_path(
      vue: analyses_vue,
      debut: params[:debut],
      fin: params[:fin]
    )
  end

  def analyses_quick_period_presets
    quick_period_definitions
  end

  def analyses_period_params(debut:, fin:, **extra)
    analyses_filter_params(include_dates: false)
      .merge(vue: analyses_vue)
      .merge(extra)
      .merge(debut: debut.to_date, fin: fin.to_date)
  end

  private

  def quick_period_definitions
    today = Date.current
    prev_month = today.prev_month
    default_debut, default_fin = default_analyses_period
    [
      ["Aujourd'hui", [today, today]],
      ["30 jours", [default_debut, default_fin]],
      ["Mois précédent", [prev_month.beginning_of_month, prev_month.end_of_month]],
      ["Mois courant", [today.beginning_of_month, today.end_of_month]]
    ]
  end

  def parse_date(value)
    Date.parse(value.to_s) rescue nil
  end
end
