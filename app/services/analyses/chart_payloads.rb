# frozen_string_literal: true

module Analyses
  class ChartPayloads
    # Palette adoucie (pro / admin) — une teinte dominante + neutres slate.
    BLUE = "rgb(74, 111, 165)".freeze # bleu désaturé
    GREEN = "rgb(74, 138, 110)".freeze
    GOLD = "rgb(168, 132, 58)".freeze
    ROSE = "rgb(168, 96, 118)".freeze
    SLATE_MUTED = "rgb(176, 184, 196)".freeze

    # Séries récurrentes — même métrique = même couleur d’un chart à l’autre.
    SERIES_CA = BLUE
    SERIES_QTY = "rgb(148, 163, 184)".freeze       # quantités catalogue
    SERIES_COMMANDES = "rgb(168, 148, 196)".freeze  # commandes (lavande) — tranche CA bleu / articles sauge
    SERIES_ARTICLES = "rgb(122, 168, 148)".freeze   # articles (sauge)
    SERIES_ESHOP = "rgb(224, 124, 64)".freeze       # canal e-shop / Stripe — orange, distinct du bleu boutique
    SERIES_TOTAL = "rgb(71, 85, 105)".freeze        # total multi-séries (slate)
    # Catalogue type / catégorie — distinct du gris+bleu loc/vente à côté.
    SERIES_CATALOG_QTY = "rgb(168, 148, 196)".freeze  # lavande
    SERIES_CATALOG_CA = "rgb(196, 148, 100)".freeze   # ambre doux

    # Modes de paiement : bleu / vert / gris / jaune / orange Stripe — pastels adoucis.
    PAYMENT_LABELS = %w[CB Espèces Chèque Virement Stripe].freeze
    PAYMENT_COLORS = [
      "rgb(130, 170, 220)",  # CB — bleu pastel
      "rgb(130, 186, 158)",  # Espèces — vert pastel
      "rgb(176, 184, 196)",  # Chèque — gris doux
      "rgb(220, 192, 118)",  # Virement — jaune pastel
      SERIES_ESHOP           # Stripe — orange, aligné canal e-shop
    ].freeze

    LOC_VENTE_COLORS = [SLATE_MUTED, BLUE].freeze

    # Teintes assez soutenues pour rester lisibles en courbes superposées.
    EQUIPE_PASTEL_COLORS = [
      "rgb(196, 92, 118)",  # rose
      "rgb(74, 132, 176)",  # bleu
      "rgb(74, 148, 110)",  # vert
      "rgb(196, 132, 74)",  # ambre
      "rgb(132, 108, 176)", # lavande
      "rgb(64, 158, 148)",  # menthe
      "rgb(176, 108, 92)",  # terracotta
      "rgb(100, 116, 184)", # pervenche
      "rgb(168, 148, 64)",  # olive
      "rgb(168, 96, 140)",  # mauve
      "rgb(80, 148, 164)",  # bleu gris
      "rgb(184, 112, 104)"  # corail
    ].freeze

    GRID_COLOR = "rgba(15, 23, 42, 0.04)".freeze
    TICK_COLOR = "rgb(100, 116, 139)".freeze

    def self.equipe_pastel_color(index)
      EQUIPE_PASTEL_COLORS[index % EQUIPE_PASTEL_COLORS.length]
    end

    def initialize(helper)
      @helper = helper
    end

    def build(key)
      case key.to_sym
      when :synthese_timeline_mixed then synthese_timeline_mixed
      when :ca_payment_modes_doughnut then ca_payment_modes_doughnut
      when :ca_transactions_timeline then ca_transactions_timeline
      when :ca_channels_timeline then ca_channels_timeline
      when :ca_ratios_timeline then ca_ratios_timeline
      when :locvente_qty_doughnut then locvente_qty_doughnut
      when :articles_locvente_ca_doughnut then articles_locvente_ca_doughnut
      when :transactions_euro_doughnut then transactions_euro_doughnut
      when :profiles_grouped then profiles_grouped
      when :profiles_ca_transactions then profiles_ca_transactions
      when :profiles_ca_doughnut then profiles_ca_doughnut
      when :profiles_ca_timeline then profiles_ca_timeline
      when :catalog_types_bars then catalog_metric_bars(:type, :qty)
      when :catalog_types_bars_ca then catalog_metric_bars(:type, :ca)
      when :catalog_categories_bars then catalog_metric_bars(:categorie, :qty)
      when :catalog_categories_bars_ca then catalog_metric_bars(:categorie, :ca)
      else
        nil
      end
    end

    private

    def h
      @helper
    end

    def synthese_timeline_mixed
      ca_hash = h.instance_variable_get(:@groupedByDateCa) || {}
      cmd_hash = h.instance_variable_get(:@groupedByDate) || {}
      art_hash = h.instance_variable_get(:@groupedByDateArticles) || {}
      labels = timeline_labels(ca_hash, cmd_hash, art_hash)
      ca_values = values_for_labels(labels, ca_hash, integer: true)
      cmd_values = values_for_labels(labels, cmd_hash, integer: true)
      art_values = values_for_labels(labels, art_hash, integer: true)
      sparse_bars = use_sparse_day_bars?(labels)

      ca_dataset = if sparse_bars
                     {
                       type: "bar",
                       label: "CA (€)",
                       data: ca_values,
                       yAxisID: "y",
                       backgroundColor: rgba_fill(SERIES_CA, 0.75),
                       hoverBackgroundColor: rgba_fill(SERIES_CA, 0.9),
                       borderWidth: 0,
                       borderRadius: { topLeft: 3, topRight: 3, bottomLeft: 0, bottomRight: 0 },
                       borderSkipped: false,
                       barPercentage: 0.9,
                       categoryPercentage: 0.75,
                       maxBarThickness: 48,
                       order: 2
                     }
                   else
                     {
                       type: "line",
                       label: "CA (€)",
                       data: ca_values,
                       yAxisID: "y",
                       borderColor: SERIES_CA,
                       backgroundColor: rgba_fill(SERIES_CA, 0.06),
                       borderWidth: 2.5,
                       borderCapStyle: "round",
                       borderJoinStyle: "round",
                       fill: true,
                       tension: line_tension,
                       pointRadius: line_point_radius(labels.size),
                       pointHoverRadius: 4,
                       pointHitRadius: 10,
                       pointBackgroundColor: SERIES_CA,
                       pointBorderColor: "#fff",
                       pointBorderWidth: 1.5,
                       order: 2
                     }
                   end

      {
        type: "bar",
        data: {
          labels: labels,
          datasets: [
            ca_dataset,
            {
              type: "bar",
              label: "Commandes",
              data: cmd_values,
              yAxisID: "y1",
              backgroundColor: rgba_fill(SERIES_COMMANDES, 0.72),
              hoverBackgroundColor: rgba_fill(SERIES_COMMANDES, 0.88),
              borderWidth: 0,
              borderRadius: { topLeft: 3, topRight: 3, bottomLeft: 0, bottomRight: 0 },
              borderSkipped: false,
              barPercentage: 0.9,
              categoryPercentage: 0.75,
              maxBarThickness: sparse_bars ? 48 : nil,
              order: 1
            }.compact,
            {
              type: "bar",
              label: "Articles",
              data: art_values,
              yAxisID: "y1",
              backgroundColor: rgba_fill(SERIES_ARTICLES, 0.72),
              hoverBackgroundColor: rgba_fill(SERIES_ARTICLES, 0.88),
              borderWidth: 0,
              borderRadius: { topLeft: 3, topRight: 3, bottomLeft: 0, bottomRight: 0 },
              borderSkipped: false,
              barPercentage: 0.9,
              categoryPercentage: 0.75,
              maxBarThickness: sparse_bars ? 48 : nil,
              order: 1
            }.compact
          ]
        },
        options: mixed_timeline_options(left_title: "CA (€)", right_title: "Nombre"),
        _tooltip: "mixed",
        _grain: grain_string
      }
    end

    def ca_payment_modes_doughnut
      values = [
        h.instance_variable_get(:@totalPrixCaCb),
        h.instance_variable_get(:@totalPrixCaEspeces),
        h.instance_variable_get(:@totalPrixCaCheque),
        h.instance_variable_get(:@totalPrixCaVirement),
        h.instance_variable_get(:@totalPrixCaStripe)
      ].map { |v| v.to_d.round.to_i }

      {
        type: "doughnut",
        data: {
          labels: PAYMENT_LABELS,
          datasets: [{
            data: values,
            backgroundColor: PAYMENT_COLORS,
            borderWidth: 0,
            borderRadius: 4,
            hoverOffset: 6,
            spacing: 2
          }]
        },
        options: doughnut_options,
        _tooltip: "money",
        _centerText: [
          "#{h.analyses_donut_amount_label(h.instance_variable_get(:@totalPrixCa))} € TTC",
          "#{h.analyses_donut_ht_label(h.instance_variable_get(:@totalPrixCa))} € HT"
        ]
      }
    end

    # CA encaissé + transactions (€) — deux courbes, même axe.
    def ca_transactions_timeline
      ca_hash = h.instance_variable_get(:@groupedByDateCa) || {}
      tx_hash = h.instance_variable_get(:@groupedByDateTransactions) || {}
      labels = timeline_labels(ca_hash, tx_hash)
      sparse = use_sparse_day_bars?(labels)

      {
        type: sparse ? "bar" : "line",
        data: {
          labels: labels,
          datasets: [
            line_or_bar_dataset(
              "CA encaissé (€)",
              values_for_labels(labels, ca_hash, integer: true),
              SERIES_CA,
              labels: labels,
              fill: true
            ),
            line_or_bar_dataset(
              "Transactions (€)",
              values_for_labels(labels, tx_hash, integer: true),
              GREEN,
              labels: labels,
              fill: false,
              border_dash: [5, 4],
              tension: 0.35
            )
          ]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          interaction: { mode: "index", intersect: false },
          plugins: { legend: legend_options },
          scales: {
            x: axis_x,
            y: axis_y(title: "€")
          }
        },
        _tooltip: "money",
        _grain: grain_string
      }
    end

    # Boutique vs e-shop (€) — deux courbes, même axe.
    def ca_channels_timeline
      boutique_hash = h.instance_variable_get(:@groupedByDateCaBoutique) || {}
      eshop_hash = h.instance_variable_get(:@groupedByDateCaEshop) || {}
      labels = timeline_labels(boutique_hash, eshop_hash)
      sparse = use_sparse_day_bars?(labels)

      {
        type: sparse ? "bar" : "line",
        data: {
          labels: labels,
          datasets: [
            line_or_bar_dataset(
              "Boutique (€)",
              values_for_labels(labels, boutique_hash, integer: true),
              SERIES_CA,
              labels: labels,
              fill: true
            ),
            line_or_bar_dataset(
              "E-shop (€)",
              values_for_labels(labels, eshop_hash, integer: true),
              SERIES_ESHOP,
              labels: labels,
              fill: false,
              border_dash: [5, 4],
              tension: 0.35
            )
          ]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          interaction: { mode: "index", intersect: false },
          plugins: { legend: legend_options },
          scales: {
            x: axis_x,
            y: axis_y(title: "CA (€)")
          }
        },
        _tooltip: "channels_money",
        _grain: grain_string
      }
    end

    # Panier moyen (€) + articles (qté) / commande, bucket par bucket.
    def ca_ratios_timeline
      ca_hash = h.instance_variable_get(:@groupedByDateCa) || {}
      cmd_hash = h.instance_variable_get(:@groupedByDate) || {}
      art_hash = h.instance_variable_get(:@groupedByDateArticles) || {}
      labels = timeline_labels(ca_hash, cmd_hash, art_hash)
      sparse = use_sparse_day_bars?(labels)

      panier_values = labels.map do |bucket|
        cmds = cmd_hash.fetch(bucket, 0).to_i
        next nil if cmds.zero?

        (ca_hash.fetch(bucket, 0).to_d / cmds).round.to_i
      end

      art_per_cmd_values = labels.map do |bucket|
        cmds = cmd_hash.fetch(bucket, 0).to_i
        next nil if cmds.zero?

        (art_hash.fetch(bucket, 0).to_d / cmds).round(1)
      end

      {
        type: sparse ? "bar" : "line",
        data: {
          labels: labels,
          datasets: [
            line_or_bar_dataset(
              "Panier moyen (€)",
              panier_values,
              BLUE,
              labels: labels,
              fill: true,
              y_axis_id: "y",
              span_gaps: true
            ),
            line_or_bar_dataset(
              "Art. / commande",
              art_per_cmd_values,
              GOLD,
              labels: labels,
              fill: false,
              border_dash: [5, 4],
              tension: 0.35,
              y_axis_id: "y1",
              span_gaps: true
            )
          ]
        },
        options: mixed_timeline_options(left_title: "Panier moyen (€)", right_title: "Art. / commande"),
        _tooltip: "mixed",
        _grain: grain_string
      }
    end

    def locvente_qty_doughnut
      loc_vente_doughnut(
        data: [h.instance_variable_get(:@nbLoc).to_i, h.instance_variable_get(:@nbVente).to_i],
        colors: LOC_VENTE_COLORS,
        tooltip: "locvente_qty",
        center_text: [
          h.instance_variable_get(:@nbTotalArticles).to_s,
          "qté articles"
        ]
      )
    end

    def articles_locvente_ca_doughnut
      loc_ca = h.instance_variable_get(:@caLocArticles).to_d.round.to_i
      vente_ca = h.instance_variable_get(:@caVenteArticles).to_d.round.to_i
      total_ca = loc_ca + vente_ca

      loc_vente_doughnut(
        data: [loc_ca, vente_ca],
        colors: LOC_VENTE_COLORS,
        tooltip: "locvente_money",
        center_text: [
          "#{h.analyses_donut_amount_label(total_ca)} €",
          "CA lignes"
        ]
      )
    end

    def transactions_euro_doughnut
      loc = h.instance_variable_get(:@totalTransactionsLoc).to_d
      vente = h.instance_variable_get(:@totalTransactionsVente).to_d
      ttc = h.instance_variable_get(:@totalTransactions).to_d

      loc_vente_doughnut(
        data: [loc.round.to_i, vente.round.to_i],
        colors: LOC_VENTE_COLORS,
        tooltip: "locvente_money",
        center_text: [
          "#{h.analyses_donut_amount_label(ttc)} € TTC",
          "#{h.analyses_donut_ht_label(ttc)} € HT"
        ]
      )
    end

    # Doughnut Location / Vente (une métrique : qté ou €).
    def loc_vente_doughnut(data:, colors:, tooltip:, center_text:)
      slice_labels = %w[Location Vente]
      ring_border = "rgb(255, 255, 255)"

      {
        type: "doughnut",
        data: {
          labels: slice_labels,
          datasets: [{
            data: data,
            backgroundColor: colors,
            borderWidth: 2,
            borderColor: ring_border,
            hoverBorderWidth: 2,
            hoverBorderColor: ring_border,
            borderRadius: 4,
            hoverOffset: 6,
            spacing: 2
          }]
        },
        options: doughnut_options.merge(cutout: "62%"),
        _tooltip: tooltip,
        _centerText: center_text
      }
    end

    def profiles_ca_doughnut
      stats = (h.instance_variable_get(:@stats_par_profile) || [])
                .sort_by { |r| [-r[:ca].to_d, -r[:commandes].to_i] }
                .select { |r| r[:ca].to_d.positive? }
      labels = stats.map { |r| r[:profile] }
      values = stats.map { |r| r[:ca].to_d.round.to_i }
      colors = stats.each_with_index.map do |row, index|
        row[:couleur].presence || self.class.equipe_pastel_color(index)
      end
      total = values.sum
      ring_border = "rgb(255, 255, 255)"

      {
        type: "doughnut",
        data: {
          labels: labels,
          datasets: [{
            data: values,
            backgroundColor: colors,
            borderWidth: 2,
            borderColor: ring_border,
            hoverBorderWidth: 2,
            hoverBorderColor: ring_border,
            borderRadius: 4,
            hoverOffset: 6,
            spacing: 2
          }]
        },
        options: doughnut_options.merge(cutout: "62%"),
        _tooltip: "money",
        _centerText: [
          "#{h.analyses_donut_amount_label(total)} €",
          (stats.size > 1 ? "CA équipe" : "CA vendeur")
        ]
      }
    end

    def profiles_grouped
      stats = (h.instance_variable_get(:@stats_par_profile) || [])
                .sort_by { |r| [-r[:ca].to_d, -r[:commandes].to_i] }
      labels = stats.map { |r| r[:profile] }
      values = stats.map { |r| r[:ca].to_d.round.to_i }
      colors = stats.each_with_index.map do |row, index|
        row[:couleur].presence || self.class.equipe_pastel_color(index)
      end

      {
        type: "bar",
        data: {
          labels: labels,
          datasets: [{
            label: "CA (€)",
            data: values,
            backgroundColor: colors.map { |c| rgba_fill(c, 0.75) },
            hoverBackgroundColor: colors.map { |c| rgba_fill(c, 0.9) },
            borderRadius: 5,
            borderSkipped: false,
            borderWidth: 0,
            barPercentage: 0.72,
            categoryPercentage: 0.78
          }]
        },
        options: {
          indexAxis: "y",
          responsive: true,
          maintainAspectRatio: false,
          plugins: { legend: { display: false } },
          scales: {
            x: {
              beginAtZero: true,
              border: { display: false },
              title: {
                display: true,
                text: "CA (€)",
                color: TICK_COLOR,
                font: { size: 11, weight: "500" }
              },
              ticks: { precision: 0, color: TICK_COLOR, font: { size: 11 } },
              grid: { color: GRID_COLOR, drawBorder: false }
            },
            y: {
              ticks: { color: TICK_COLOR, font: { size: 11, weight: "500" } },
              grid: { display: false },
              border: { display: false }
            }
          }
        },
        _tooltip: "money"
      }
    end

    # Synthèse : CA (encaissements) + transactions (lignes) par vendeur, même axe €.
    def profiles_ca_transactions
      stats = (h.instance_variable_get(:@stats_par_profile) || [])
                .sort_by { |r| [-r[:ca].to_d, -r[:transactions].to_d] }
      labels = stats.map { |r| r[:profile] }
      ca_values = stats.map { |r| r[:ca].to_d.round.to_i }
      tx_values = stats.map { |r| r[:transactions].to_d.round.to_i }

      {
        type: "bar",
        data: {
          labels: labels,
          datasets: [
            {
              label: "CA (€)",
              data: ca_values,
              backgroundColor: rgba_fill(SERIES_CA, 0.75),
              hoverBackgroundColor: rgba_fill(SERIES_CA, 0.9),
              borderWidth: 0,
              borderRadius: 4,
              borderSkipped: false,
              barPercentage: 0.85,
              categoryPercentage: 0.7
            },
            {
              label: "Transactions (€)",
              data: tx_values,
              backgroundColor: rgba_fill(GREEN, 0.65),
              hoverBackgroundColor: rgba_fill(GREEN, 0.82),
              borderWidth: 0,
              borderRadius: 4,
              borderSkipped: false,
              barPercentage: 0.85,
              categoryPercentage: 0.7
            }
          ]
        },
        options: {
          indexAxis: "y",
          responsive: true,
          maintainAspectRatio: false,
          interaction: { mode: "index", intersect: false },
          plugins: { legend: legend_options },
          scales: {
            x: {
              beginAtZero: true,
              border: { display: false },
              ticks: { precision: 0, color: TICK_COLOR, font: { size: 11 } },
              grid: { color: GRID_COLOR, drawBorder: false }
            },
            y: {
              ticks: { color: TICK_COLOR, font: { size: 11, weight: "500" } },
              grid: { display: false },
              border: { display: false }
            }
          }
        },
        _tooltip: "money"
      }
    end

    def profiles_ca_timeline
      stats = (h.instance_variable_get(:@stats_par_profile) || []).sort_by { |r| -r[:ca].to_f }
      hashes = stats.map { |row| row[:ca_by_day] || {} }
      labels = timeline_labels(*hashes)
      sparse = use_sparse_day_bars?(labels)

      {
        type: sparse ? "bar" : "line",
        data: {
          labels: labels,
          datasets: stats.each_with_index.map do |row, index|
            color = row[:couleur].presence || self.class.equipe_pastel_color(index)
            values = labels.map { |bucket|
              value = row.dig(:ca_by_day, bucket)
              value.nil? ? nil : value.to_d.round.to_i
            }
            line_or_bar_dataset(
              row[:profile],
              values,
              color,
              labels: labels,
              fill: false,
              tension: 0.35,
              span_gaps: true
            )
          end
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          interaction: { mode: "nearest", axis: "x", intersect: false },
          plugins: { legend: legend_options },
          scales: {
            x: axis_x,
            y: axis_y(title: "CA (€)")
          }
        },
        _tooltip: "money",
        _grain: grain_string
      }
    end

    # Une métrique à la fois (bascule Quantité / CA) — lisible en colonne étroite.
    def catalog_metric_bars(kind, metric)
      rows = catalog_rows_for(kind, metric)
      labels = rows.map { |r| r[:label] }
      by_ca = metric.to_sym == :ca
      values = rows.map { |r| by_ca ? r[:ca_lignes].to_d.round.to_i : r[:quantite].to_i }
      color = by_ca ? SERIES_CATALOG_CA : SERIES_CATALOG_QTY
      label = by_ca ? "CA (€)" : "Quantité"
      axis_title = by_ca ? "CA (€)" : "Quantité"

      {
        type: "bar",
        data: {
          labels: labels,
          datasets: [{
            label: label,
            data: values,
            backgroundColor: rgba_fill(color, 0.72),
            hoverBackgroundColor: rgba_fill(color, 0.88),
            borderRadius: 5,
            borderSkipped: false,
            borderWidth: 0,
            barPercentage: 0.85,
            categoryPercentage: 0.7
          }]
        },
        options: {
          indexAxis: "y",
          responsive: true,
          maintainAspectRatio: false,
          interaction: { mode: "index", intersect: false },
          plugins: { legend: { display: false } },
          scales: {
            y: {
              ticks: { color: TICK_COLOR, font: { size: 11 } },
              grid: { display: false },
              border: { display: false }
            },
            x: {
              beginAtZero: true,
              ticks: { precision: 0, color: color, font: { size: 10 } },
              grid: { color: GRID_COLOR, drawBorder: false },
              border: { display: false },
              title: {
                display: true,
                text: axis_title,
                color: TICK_COLOR,
                font: { size: 10, weight: "500" }
              }
            }
          }
        },
        _tooltip: by_ca ? "money" : "integer"
      }
    end

    def catalog_rows_for(kind, metric)
      by_ca = metric.to_sym == :ca
      if kind == :type
        h.instance_variable_get(by_ca ? :@catalog_by_type_by_ca : :@catalog_by_type) || []
      else
        h.instance_variable_get(by_ca ? :@catalog_by_categorie_by_ca : :@catalog_by_categorie) || []
      end
    end

    def timeline_grain
      (h.instance_variable_get(:@timeline_grain).presence || :day).to_sym
    end

    def grain_string
      timeline_grain.to_s
    end

    def use_sparse_day_bars?(labels)
      timeline_grain == :day && Array(labels).size <= 2
    end

    def line_tension
      timeline_grain == :hour ? 0 : 0.4
    end

    def line_point_radius(label_count)
      return 3 if timeline_grain == :hour
      return 4 if label_count.to_i <= 2

      0
    end

    def timeline_labels(*hashes)
      data_keys = hashes.flat_map(&:keys)
      debut = h.instance_variable_get(:@datedebut)
      fin = h.instance_variable_get(:@datefin)
      TimelineBuckets.filled_labels(
        debut: debut,
        fin: fin,
        grain: timeline_grain,
        data_keys: data_keys
      )
    end

    def line_or_bar_dataset(label, data, color, labels:, fill: false, border_dash: nil, tension: nil, y_axis_id: nil, span_gaps: true)
      if use_sparse_day_bars?(labels)
        {
          label: label,
          data: data,
          yAxisID: y_axis_id,
          backgroundColor: rgba_fill(color, fill ? 0.75 : 0.55),
          hoverBackgroundColor: rgba_fill(color, 0.9),
          borderWidth: 0,
          borderRadius: { topLeft: 3, topRight: 3, bottomLeft: 0, bottomRight: 0 },
          borderSkipped: false,
          barPercentage: 0.85,
          categoryPercentage: 0.7,
          maxBarThickness: 48,
          spanGaps: span_gaps
        }.compact
      else
        line_dataset(
          label,
          data,
          color,
          fill: fill,
          border_dash: border_dash,
          tension: tension || line_tension,
          y_axis_id: y_axis_id,
          span_gaps: span_gaps,
          labels: labels
        )
      end
    end

    def line_dataset(label, data, color, fill: false, border_dash: nil, tension: nil, y_axis_id: nil, span_gaps: true, labels: nil)
      size = Array(labels || data).size
      {
        label: label,
        data: data,
        yAxisID: y_axis_id,
        borderColor: color,
        backgroundColor: rgba_fill(color, fill ? 0.08 : 0.0),
        borderWidth: fill ? 2.25 : 2,
        borderDash: border_dash,
        borderCapStyle: "round",
        borderJoinStyle: "round",
        fill: fill,
        tension: tension.nil? ? line_tension : tension,
        spanGaps: span_gaps,
        pointRadius: line_point_radius(size),
        pointHoverRadius: 5,
        pointHitRadius: 12,
        pointBackgroundColor: color,
        pointBorderColor: "#fff",
        pointBorderWidth: 1.5
      }.compact
    end

    def mixed_timeline_options(left_title:, right_title:)
      {
        responsive: true,
        maintainAspectRatio: false,
        interaction: { mode: "index", intersect: false },
        plugins: {
          legend: legend_options
        },
        scales: {
          x: axis_x,
          y: axis_y(title: left_title),
          y1: {
            type: "linear",
            position: "right",
            beginAtZero: true,
            grid: { drawOnChartArea: false },
            border: { display: false },
            title: {
              display: true,
              text: right_title,
              color: TICK_COLOR,
              font: { size: 11, weight: "500" }
            },
            ticks: { precision: 0, color: TICK_COLOR, font: { size: 11 } }
          }
        }
      }
    end

    def doughnut_options(legend: true)
      {
        responsive: true,
        maintainAspectRatio: true,
        aspectRatio: 1,
        cutout: "70%",
        plugins: {
          legend: legend ? legend_options.merge(position: "bottom") : { display: false }
        }
      }
    end

    def legend_options
      {
        display: true,
        position: "bottom",
        labels: {
          usePointStyle: true,
          pointStyle: "circle",
          padding: 10,
          boxWidth: 8,
          boxHeight: 8,
          color: TICK_COLOR,
          font: { size: 11, weight: "500" }
        }
      }
    end

    def axis_x
      {
        ticks: {
          maxRotation: 0,
          minRotation: 0,
          autoSkip: true,
          maxTicksLimit: timeline_grain == :hour ? 16 : 8,
          color: TICK_COLOR,
          font: { size: 10 }
        },
        grid: { display: false },
        border: { display: false }
      }
    end

    def axis_y(title: nil)
      {
        type: "linear",
        position: "left",
        beginAtZero: true,
        border: { display: false },
        title: if title
                 {
                   display: true,
                   text: title,
                   color: TICK_COLOR,
                   font: { size: 11, weight: "500" }
                 }
               else
                 { display: false }
               end,
        ticks: { precision: 0, color: TICK_COLOR, font: { size: 11 } },
        grid: { color: GRID_COLOR, drawBorder: false }
      }
    end

    # Conservé pour specs / callers qui n'ont pas @datedebut.
    def aligned_day_labels(*hashes)
      TimelineBuckets.filled_labels(
        debut: nil,
        fin: nil,
        grain: :day,
        data_keys: hashes.flat_map(&:keys)
      )
    end

    def values_for_labels(labels, hash, integer: false)
      labels.map do |label|
        value = hash.fetch(label, 0)
        integer ? value.to_i : value.to_d.round.to_i
      end
    end

    def rgba_fill(rgb, alpha = 0.15)
      m = rgb.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/)
      return rgb unless m

      "rgba(#{m[1]}, #{m[2]}, #{m[3]}, #{alpha})"
    end
  end
end
