# frozen_string_literal: true

module Analyses
  class ChartPayloads
    # Palette adoucie (pro / admin) — une teinte dominante + neutres slate.
    BLUE = "rgb(74, 111, 165)".freeze # bleu désaturé
    GREEN = "rgb(74, 138, 110)".freeze
    GOLD = "rgb(168, 132, 58)".freeze
    ROSE = "rgb(168, 96, 118)".freeze
    SLATE = "rgb(100, 116, 139)".freeze
    SLATE_SOFT = "rgb(148, 163, 184)".freeze
    SLATE_MUTED = "rgb(176, 184, 196)".freeze

    # Modes de paiement : bleu / vert / gris / jaune / bleu Stripe — pastels adoucis.
    PAYMENT_LABELS = %w[CB Espèces Chèque Virement Stripe].freeze
    PAYMENT_COLORS = [
      "rgb(130, 170, 220)",  # CB — bleu pastel
      "rgb(130, 186, 158)",  # Espèces — vert pastel
      "rgb(176, 184, 196)",  # Chèque — gris doux
      "rgb(220, 192, 118)",  # Virement — jaune pastel
      "rgb(96, 148, 230)"    # Stripe — bleu un peu plus vif, toujours doux
    ].freeze

    LOC_VENTE_COLORS = [SLATE_MUTED, BLUE].freeze
    TRANSACTIONS_COLORS = [GREEN, "rgb(58, 118, 92)"].freeze

    # Pastels distincts (teintes espacées) pour lignes / barres multi-vendeurs.
    EQUIPE_PASTEL_COLORS = [
      "rgb(214, 132, 154)", # rose
      "rgb(122, 168, 196)", # bleu ciel
      "rgb(142, 186, 148)", # vert sauge
      "rgb(212, 168, 118)", # pêche
      "rgb(168, 148, 196)", # lavande
      "rgb(122, 186, 178)", # menthe
      "rgb(196, 148, 132)", # terracotta doux
      "rgb(148, 158, 204)", # pervenche
      "rgb(196, 186, 122)", # beurre
      "rgb(186, 148, 168)", # mauve
      "rgb(132, 178, 186)", # bleu gris
      "rgb(204, 158, 148)"  # corail pâle
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
      when :ca_timeline then ca_timeline
      when :ca_ratios_timeline then ca_ratios_timeline
      when :articles_timeline then articles_timeline
      when :articles_locvente_doughnut then articles_locvente_doughnut
      when :transactions_doughnut then transactions_doughnut
      when :transactions_timeline then transactions_timeline
      when :profiles_grouped then profiles_grouped
      when :profiles_ca_timeline then profiles_ca_timeline
      when :catalog_types_horizontal then catalog_horizontal(:type)
      when :catalog_categories_horizontal then catalog_horizontal(:categorie)
      else
        nil
      end
    end

    private

    def h
      @helper
    end

    def synthese_timeline_mixed
      labels = aligned_day_labels(h.instance_variable_get(:@groupedByDateCa), h.instance_variable_get(:@groupedByDate))
      ca_values = values_for_labels(labels, h.instance_variable_get(:@groupedByDateCa), integer: true)
      cmd_values = values_for_labels(labels, h.instance_variable_get(:@groupedByDate), integer: true)

      {
        type: "bar",
        data: {
          labels: labels,
          datasets: [
            {
              type: "line",
              label: "CA (€)",
              data: ca_values,
              yAxisID: "y",
              borderColor: BLUE,
              backgroundColor: rgba_fill(BLUE, 0.08),
              borderWidth: 2.25,
              borderCapStyle: "round",
              borderJoinStyle: "round",
              fill: true,
              tension: 0.4,
              pointRadius: 0,
              pointHoverRadius: 4,
              pointHitRadius: 10,
              pointBackgroundColor: BLUE,
              pointBorderColor: "#fff",
              pointBorderWidth: 1.5,
              order: 1
            },
            {
              type: "bar",
              label: "Commandes",
              data: cmd_values,
              yAxisID: "y1",
              backgroundColor: rgba_fill(SLATE, 0.28),
              hoverBackgroundColor: rgba_fill(SLATE, 0.42),
              borderRadius: 6,
              borderSkipped: false,
              borderWidth: 0,
              barPercentage: 0.55,
              categoryPercentage: 0.7,
              order: 2
            }
          ]
        },
        options: mixed_timeline_options(left_title: "CA (€)", right_title: "Commandes")
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
        _centerText: [
          "#{h.analyses_donut_amount_label(h.instance_variable_get(:@totalPrixCa))} € TTC",
          "#{h.analyses_donut_ht_label(h.instance_variable_get(:@totalPrixCa))} € HT"
        ]
      }
    end

    def ca_timeline
      labels, values = series_from_day_hash(h.instance_variable_get(:@groupedByDateCa))
      line_chart("CA (€)", labels, values, BLUE)
    end

    # Panier moyen (€) + articles (qté) / commande, jour par jour.
    def ca_ratios_timeline
      ca_hash = h.instance_variable_get(:@groupedByDateCa) || {}
      cmd_hash = h.instance_variable_get(:@groupedByDate) || {}
      art_hash = h.instance_variable_get(:@groupedByDateArticles) || {}
      labels = aligned_day_labels(ca_hash, cmd_hash, art_hash)

      panier_values = labels.map do |day|
        cmds = cmd_hash.fetch(day, 0).to_i
        next nil if cmds.zero?

        (ca_hash.fetch(day, 0).to_d / cmds).round.to_i
      end

      art_per_cmd_values = labels.map do |day|
        cmds = cmd_hash.fetch(day, 0).to_i
        next nil if cmds.zero?

        (art_hash.fetch(day, 0).to_d / cmds).round(1)
      end

      {
        type: "line",
        data: {
          labels: labels,
          datasets: [
            {
              label: "Panier moyen (€)",
              data: panier_values,
              yAxisID: "y",
              borderColor: BLUE,
              backgroundColor: rgba_fill(BLUE, 0.08),
              borderWidth: 2.25,
              borderCapStyle: "round",
              borderJoinStyle: "round",
              fill: true,
              tension: 0.4,
              spanGaps: true,
              pointRadius: 0,
              pointHoverRadius: 4,
              pointHitRadius: 10,
              pointBackgroundColor: BLUE,
              pointBorderColor: "#fff",
              pointBorderWidth: 1.5
            },
            {
              label: "Art. / commande",
              data: art_per_cmd_values,
              yAxisID: "y1",
              borderColor: GOLD,
              backgroundColor: rgba_fill(GOLD, 0.06),
              borderWidth: 2,
              borderDash: [5, 4],
              borderCapStyle: "round",
              borderJoinStyle: "round",
              fill: false,
              tension: 0.35,
              spanGaps: true,
              pointRadius: 0,
              pointHoverRadius: 4,
              pointHitRadius: 10,
              pointBackgroundColor: GOLD,
              pointBorderColor: "#fff",
              pointBorderWidth: 1.5
            }
          ]
        },
        options: mixed_timeline_options(left_title: "Panier moyen (€)", right_title: "Art. / commande")
      }
    end

    def articles_timeline
      labels, values = series_from_day_hash(h.instance_variable_get(:@groupedByDateArticles), integer: true)
      line_chart("Quantité d'articles", labels, values, SLATE, integer_ticks: true)
    end

    def articles_locvente_doughnut
      values = [
        h.instance_variable_get(:@nbLoc).to_i,
        h.instance_variable_get(:@nbVente).to_i
      ]
      {
        type: "doughnut",
        data: {
          labels: %w[Locations Ventes],
          datasets: [{
            data: values,
            backgroundColor: LOC_VENTE_COLORS,
            borderWidth: 0,
            borderRadius: 4,
            hoverOffset: 6,
            spacing: 2
          }]
        },
        options: doughnut_options,
        _centerText: [
          h.instance_variable_get(:@nbTotalArticles).to_s,
          "articles"
        ]
      }
    end

    def transactions_doughnut
      loc = h.instance_variable_get(:@totalTransactionsLoc).to_d
      vente = h.instance_variable_get(:@totalTransactionsVente).to_d
      ttc = h.instance_variable_get(:@totalTransactions).to_d
      {
        type: "doughnut",
        data: {
          labels: %w[Locations Ventes],
          datasets: [{
            data: [loc.round.to_i, vente.round.to_i],
            backgroundColor: TRANSACTIONS_COLORS,
            borderWidth: 0,
            borderRadius: 4,
            hoverOffset: 6,
            spacing: 2
          }]
        },
        options: doughnut_options,
        _centerText: [
          "#{h.analyses_donut_amount_label(ttc)} € TTC",
          "#{h.analyses_donut_ht_label(ttc)} € HT"
        ]
      }
    end

    def transactions_timeline
      hash = h.instance_variable_get(:@groupedByDateTransactions)
      labels, values = series_from_day_hash(hash)
      line_chart("Transactions (€)", labels, values, GREEN)
    end

    def profiles_ca_timeline
      stats = (h.instance_variable_get(:@stats_par_profile) || []).sort_by { |r| -r[:ca].to_f }
      labels = stats.flat_map { |row| (row[:ca_by_day] || {}).keys }
                    .uniq
                    .sort_by { |day| Date.strptime(day.to_s, "%d/%m/%Y") }

      {
        type: "line",
        data: {
          labels: labels,
          datasets: stats.map do |row|
            color = row[:couleur].presence || ROSE
            {
              label: row[:profile],
              data: labels.map { |day|
                value = row.dig(:ca_by_day, day)
                value.nil? ? nil : value.to_d.round.to_i
              },
              borderColor: color,
              backgroundColor: rgba_fill(color, 0.1),
              borderWidth: 2.25,
              borderCapStyle: "round",
              borderJoinStyle: "round",
              fill: false,
              tension: 0.35,
              spanGaps: true,
              pointRadius: 0,
              pointHoverRadius: 4,
              pointHitRadius: 10,
              pointBackgroundColor: color,
              pointBorderColor: "#fff",
              pointBorderWidth: 1.5
            }
          end
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          interaction: { mode: "nearest", axis: "x", intersect: false },
          plugins: {
            legend: legend_options,
            title: { display: false }
          },
          scales: {
            x: axis_x,
            y: axis_y(title: "CA (€)")
          }
        }
      }
    end

    def profiles_grouped
      stats = (h.instance_variable_get(:@stats_par_profile) || []).sort_by { |r| -r[:ca].to_f }
      labels = stats.map { |row| row[:profile] }

      {
        type: "bar",
        data: {
          labels: labels,
          datasets: [{
            label: "CA (€)",
            data: stats.map { |r| r[:ca].to_d.round.to_i },
            backgroundColor: stats.map { |r| r[:couleur].presence || rgba_fill(ROSE, 0.85) },
            borderRadius: 6,
            borderSkipped: false,
            borderWidth: 0,
            barPercentage: 0.7,
            categoryPercentage: 0.8
          }]
        },
        options: {
          indexAxis: "y",
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: { display: false },
            title: { display: false }
          },
          scales: {
            x: axis_y(title: "CA (€)").merge(beginAtZero: true),
            y: {
              ticks: { autoSkip: false, color: TICK_COLOR, font: { size: 11 } },
              grid: { display: false },
              border: { display: false }
            }
          }
        }
      }
    end

    def catalog_horizontal(kind)
      rows = if kind == :type
               h.instance_variable_get(:@catalog_by_type) || []
             else
               h.instance_variable_get(:@catalog_by_categorie) || []
             end
      labels = rows.map { |r| r[:label] }
      values = rows.map { |r| r[:quantite].to_i }

      {
        type: "bar",
        data: {
          labels: labels,
          datasets: [{
            data: values,
            backgroundColor: catalog_bar_colors(values.length),
            borderRadius: 6,
            borderSkipped: false,
            borderWidth: 0
          }]
        },
        options: {
          indexAxis: "y",
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: { display: false },
            title: { display: false }
          },
          scales: {
            x: {
              beginAtZero: true,
              ticks: { precision: 0, color: TICK_COLOR, font: { size: 11 } },
              grid: { color: GRID_COLOR, drawBorder: false },
              border: { display: false }
            },
            y: {
              ticks: { color: TICK_COLOR, font: { size: 11 } },
              grid: { display: false },
              border: { display: false }
            }
          }
        }
      }
    end

    def line_chart(title, labels, values, color, integer_ticks: false)
      y_ticks = { precision: 0, color: TICK_COLOR, font: { size: 11 } }
      {
        type: "line",
        data: {
          labels: labels,
          datasets: [{
            label: title,
            data: values.map { |v| v.nil? ? nil : v.to_d.round.to_i },
            borderColor: color,
            backgroundColor: rgba_fill(color, 0.08),
            borderWidth: 2.25,
            borderCapStyle: "round",
            borderJoinStyle: "round",
            fill: true,
            tension: 0.4,
            pointRadius: 0,
            pointHoverRadius: 4,
            pointHitRadius: 10,
            pointBackgroundColor: color,
            pointBorderColor: "#fff",
            pointBorderWidth: 1.5
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          interaction: { mode: "index", intersect: false },
          plugins: { legend: { display: false } },
          scales: {
            x: axis_x,
            y: {
              beginAtZero: true,
              ticks: y_ticks,
              grid: { color: GRID_COLOR, drawBorder: false },
              border: { display: false }
            }
          }
        }
      }
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

    def doughnut_options
      {
        responsive: true,
        maintainAspectRatio: true,
        aspectRatio: 1,
        cutout: "70%",
        plugins: {
          legend: legend_options.merge(position: "bottom")
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
          padding: 16,
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
          maxTicksLimit: 8,
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

    def series_from_day_hash(hash, integer: false)
      return [[], []] if hash.blank?

      sorted = hash.sort_by { |day, _| Date.strptime(day.to_s, "%d/%m/%Y") }
      values = sorted.map { |_, v| integer ? v.to_i : v.to_d.round.to_i }
      [sorted.map(&:first), values]
    end

    def aligned_day_labels(*hashes)
      hashes.flat_map(&:keys).uniq.sort_by { |day| Date.strptime(day.to_s, "%d/%m/%Y") }
    end

    def values_for_labels(labels, hash, integer: false)
      labels.map do |label|
        value = hash.fetch(label, 0)
        integer ? value.to_i : value.to_d.round.to_i
      end
    end

    def catalog_bar_colors(count)
      base = [
        "rgb(168, 132, 58)",
        "rgb(184, 152, 86)",
        "rgb(148, 124, 72)",
        SLATE_SOFT,
        SLATE
      ]
      Array.new(count) { |i| base[i % base.length] }
    end

    def rgba_fill(rgb, alpha = 0.15)
      m = rgb.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/)
      return rgb unless m

      "rgba(#{m[1]}, #{m[2]}, #{m[3]}, #{alpha})"
    end
  end
end
