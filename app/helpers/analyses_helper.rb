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

  # Barre de part : remplissage = valeur / ensemble (0–100), libellé centré dessus.
  def analyses_equipe_share_bar(label, pct, color: nil, title: nil)
    width = [[pct.to_f, 0].max, 100].min.round(1)
    style = []
    style << "--equipe-bar-color: #{color}" if color.present?
    style << "--equipe-bar-width: #{width}%"

    content_tag(
      :div,
      class: "analyses-equipe-bar",
      style: style.join("; ").presence,
      title: title.presence || label
    ) do
      safe_join([
        content_tag(:div, "", class: "analyses-equipe-bar__fill", "aria-hidden": true),
        content_tag(:span, label, class: "analyses-equipe-bar__label")
      ])
    end
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
    exclusive_keys = %i[filter_locvente filter_eshop filter_propart]
    multi_count = Admin::ProduitListingFilters::ANALYSES_MULTI_FILTER_KEYS.sum do |key|
      Admin::ProduitListingFilters.normalize_filter_values(params[key]).size
    end
    exclusive_count = exclusive_keys.count { |key| params[key].present? }
    multi_count + exclusive_count
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

  def analyses_path_without_filter(filter_key, value = nil)
    if value.present? && Admin::ProduitListingFilters::ANALYSES_MULTI_FILTER_KEYS.include?(filter_key.to_sym)
      remaining = Admin::ProduitListingFilters.normalize_filter_values(params[filter_key]) - [value.to_s]
      analyses_tab_path(analyses_vue, filter_key => remaining.presence)
    else
      analyses_tab_path(analyses_vue, filter_key => nil)
    end
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
      safe_join([
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
          multiple: true,
          keep_label: true,
          link_data: { turbo_stream: true }
        ),
        analyses_filter_selected_tags(param_key, model)
      ])
    end
  end

  def analyses_filter_selected_tags(param_key, model)
    values = Admin::ProduitListingFilters.normalize_filter_values(params[param_key])
    return "".html_safe if values.empty?

    content_tag(:div, class: "analyses-filter-selected", aria: { label: "Sélection" }) do
      safe_join(
        values.map do |id|
          name = analyses_filter_value_label(model, id)
          link_to(
            analyses_path_without_filter(param_key, id),
            class: "analyses-filter-selected__tag",
            title: "Retirer #{name}",
            data: { turbo_stream: true }
          ) do
            safe_join([
              tag.span(name, class: "text-truncate"),
              tag.span("×", class: "analyses-filter-selected__x", aria: { hidden: true })
            ])
          end
        end
      )
    end
  end

  def analyses_filter_value_label(model, id)
    return "NA" if id.to_s == "na"

    record = model.find_by(id: id)
    return id.to_s unless record

    if record.respond_to?(:full_name)
      record.full_name.presence || record.try(:nom).to_s.presence || id.to_s
    else
      record.nom.presence || id.to_s
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
    chips.concat(
      analyses_multi_filter_chips(
        :filter_profile, "Vendeur"
      ) do |id|
        profile = Profile.find_by(id: id)
        profile&.full_name.presence || profile&.prenom || "Profil ##{id}"
      end
    )
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
    chips.concat(analyses_multi_filter_chips(:filter_type_produit, "Type", TypeProduit))
    chips.concat(analyses_multi_filter_chips(:filter_categorie, "Catégorie", CategorieProduit))
    chips.concat(analyses_multi_filter_chips(:filter_fournisseur, "Fournisseur", Fournisseur))
    chips.concat(analyses_multi_filter_chips(:filter_couleur, "Couleur", Couleur))
    chips.concat(analyses_multi_filter_chips(:filter_taille, "Taille", Taille))
    chips
  end

  def analyses_multi_filter_chips(key, label, model = nil)
    Admin::ProduitListingFilters.normalize_filter_values(params[key]).map do |id|
      display =
        if id == "na"
          "NA"
        elsif block_given?
          yield(id)
        else
          model.find_by(id: id)&.nom || id
        end
      { key: key, label: label, value: display, remove_value: id }
    end
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
    truncate(name, length: 36)
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
    ca = stats.sum { |r| r[:ca].to_d }
    commandes = stats.sum { |r| r[:commandes].to_i }
    devis = stats.sum { |r| r[:devis].to_i }
    articles = stats.sum { |r| r[:articles].to_i }
    conv_base = commandes + devis

    {
      ca: ca,
      commandes: commandes,
      devis: devis,
      articles: articles,
      vendeurs: stats.size,
      panier: (commandes.positive? ? (ca / commandes).round(2) : nil),
      articles_par_commande: (commandes.positive? ? (articles.to_d / commandes).round(1) : nil),
      conversion_pct: (conv_base.positive? ? ((commandes.to_d / conv_base) * 100).round : nil)
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

  def analyses_ca_transactions_meta
    ca = @totalPrixCa.to_d
    tx = @totalTransactions.to_d
    parts = [
      "CA #{analyses_donut_amount_label(ca)} €",
      "Transactions #{analyses_donut_amount_label(tx)} €"
    ]
    if tx.positive?
      gap = (tx - ca).round
      parts << "Écart #{analyses_donut_amount_label(gap)} €" if gap != 0
    end
    parts.join(" · ")
  end

  def analyses_ca_channels_meta
    boutique = @totalPrixCaBoutique.to_d
    eshop = @totalPrixCaStripe.to_d
    total = boutique + eshop
    return "Aucun CA sur la période" if total <= 0

    b_pct = ((boutique / total) * 100).round
    e_pct = ((eshop / total) * 100).round
    [
      "Total #{analyses_donut_amount_label(total)} €",
      "Boutique #{analyses_donut_amount_label(boutique)} € (#{b_pct} %)",
      "E-shop #{analyses_donut_amount_label(eshop)} € (#{e_pct} %)"
    ].join(" · ")
  end

  def analyses_remboursements_eshop
    @totalRemboursementsEshop.to_d
  end

  def analyses_eshop_counts
    items = @stripePaymentItemsFiltres || StripePaymentItem.none
    {
      commandes: (@commandesFiltres || Commande.none).where(eshop: true).count,
      articles: items.sum(:quantity).to_i
    }
  end

  # Articles (somme des quantités) / commande — nil si aucune commande.
  def analyses_articles_par_commande
    return nil if @nbTotal.blank? || @nbTotal.to_i.zero?

    articles = @nbTotalArticles
    articles = analyses_line_metrics.quantites if articles.nil?
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
      ["Hier", [today - 1.day, today - 1.day]],
      ["7 jours", [today - 6.days, today]],
      ["30 jours", [default_debut, default_fin]],
      ["3 mois", [today - 89.days, today]],
      ["Mois courant", [today.beginning_of_month, today.end_of_month]],
      ["Mois précédent", [prev_month.beginning_of_month, prev_month.end_of_month]]
    ]
  end

  def parse_date(value)
    Date.parse(value.to_s) rescue nil
  end
end
