# frozen_string_literal: true

module Analyses
  class ChartPayloads
    # Palette alignée sur les teintes de section (bleu / vert / or / rose + neutres).
    BLUE = "rgb(59, 111, 216)".freeze
    GREEN = "rgb(42, 157, 106)".freeze
    GOLD = "rgb(184, 134, 11)".freeze
    ROSE = "rgb(184, 74, 107)".freeze
    SLATE = "rgb(100, 116, 139)".freeze
    SLATE_SOFT = "rgb(148, 163, 184)".freeze
    INDIGO = "rgb(99, 102, 241)".freeze

    PAYMENT_LABELS = %w[CB Espèces Chèque Virement Stripe].freeze
    PAYMENT_COLORS = [BLUE, GREEN, SLATE_SOFT, GOLD, INDIGO].freeze

    LOC_VENTE_COLORS = [SLATE_SOFT, BLUE].freeze
    TRANSACTIONS_COLORS = [GREEN, "rgb(30, 120, 80)"].freeze
    DOUGHNUT_BORDER = "rgb(255, 255, 255)".freeze

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
              backgroundColor: rgba_fill(BLUE, 0.12),
              fill: true,
              tension: 0.35,
              pointRadius: 2,
              pointHoverRadius: 4,
              order: 1
            },
            {
              type: "bar",
              label: "Commandes",
              data: cmd_values,
              yAxisID: "y1",
              backgroundColor: rgba_fill(ROSE, 0.55),
              borderRadius: 3,
              borderWidth: 0,
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
            borderColor: DOUGHNUT_BORDER,
            borderWidth: 2,
            hoverOffset: 4
          }]
        },
        options: doughnut_options,
        _centerText: [
          "HT: #{h.analyses_donut_ht_label(h.instance_variable_get(:@totalPrixCa))} €",
          "TTC: #{h.analyses_donut_amount_label(h.instance_variable_get(:@totalPrixCa))} €"
        ]
      }
    end

    def ca_timeline
      labels, values = series_from_day_hash(h.instance_variable_get(:@groupedByDateCa))
      line_chart("CA (€)", labels, values, BLUE)
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
          labels: %w[location vente],
          datasets: [{
            data: values,
            backgroundColor: LOC_VENTE_COLORS,
            borderColor: DOUGHNUT_BORDER,
            borderWidth: 2,
            hoverOffset: 4
          }]
        },
        options: doughnut_options,
        _centerText: ["total #{h.instance_variable_get(:@nbTotalArticles)}"]
      }
    end

    def transactions_doughnut
      loc = h.instance_variable_get(:@totalTransactionsLoc).to_d
      vente = h.instance_variable_get(:@totalTransactionsVente).to_d
      ttc = h.instance_variable_get(:@totalTransactions).to_d
      {
        type: "doughnut",
        data: {
          labels: %w[location vente],
          datasets: [{
            data: [loc.round.to_i, vente.round.to_i],
            backgroundColor: TRANSACTIONS_COLORS,
            borderColor: DOUGHNUT_BORDER,
            borderWidth: 2,
            hoverOffset: 4
          }]
        },
        options: doughnut_options,
        _centerText: [
          "HT: #{h.analyses_donut_ht_label(ttc)} €",
          "TTC: #{h.analyses_donut_amount_label(ttc)} €"
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
      series_count = [stats.length, 1].max
      # Plus de séries → un peu plus de hauteur pour séparer les courbes.
      aspect = [[2.2 - (series_count * 0.06), 1.55].max, 2.2].min

      {
        type: "line",
        data: {
          labels: labels,
          datasets: stats.map do |row|
            color = row[:couleur].presence || ROSE
            {
              label: row[:profile],
              # nil (pas 0) les jours sans CA : évite les zigzags trompeurs.
              data: labels.map { |day|
                value = row.dig(:ca_by_day, day)
                value.nil? ? nil : value.to_d.round.to_i
              },
              borderColor: color,
              backgroundColor: rgba_fill(color, 0.1),
              borderWidth: 2.5,
              borderCapStyle: "round",
              borderJoinStyle: "round",
              fill: false,
              tension: 0.25,
              spanGaps: true,
              pointRadius: 3.5,
              pointHoverRadius: 6,
              pointHitRadius: 10,
              pointBackgroundColor: color,
              pointBorderColor: "#fff",
              pointBorderWidth: 2
            }
          end
        },
        options: {
          responsive: true,
          maintainAspectRatio: true,
          aspectRatio: aspect,
          interaction: { mode: "nearest", axis: "x", intersect: false },
          plugins: {
            legend: {
              display: true,
              position: "bottom",
              labels: {
                usePointStyle: true,
                pointStyle: "circle",
                padding: 14,
                boxWidth: 10,
                boxHeight: 10,
                font: { size: 12 }
              }
            },
            title: { display: false }
          },
          scales: {
            x: {
              ticks: {
                maxRotation: 45,
                minRotation: 0,
                autoSkip: true,
                maxTicksLimit: 14
              },
              grid: { display: false }
            },
            y: {
              beginAtZero: true,
              title: { display: true, text: "CA (€)" },
              ticks: { precision: 0 },
              grid: { color: "rgba(0, 0, 0, 0.06)" }
            }
          }
        }
      }
    end

    def profiles_grouped
      stats = (h.instance_variable_get(:@stats_par_profile) || []).sort_by { |r| -r[:ca].to_f }
      labels = stats.map { |row| row[:profile] }
      n = [labels.length, 1].max
      # Plus de vendeurs → un peu plus haut, mais plafonné pour rester compact.
      aspect = [[2.8 - (n * 0.12), 1.6].max, 2.8].min

      {
        type: "bar",
        data: {
          labels: labels,
          datasets: [{
            label: "CA (€)",
            data: stats.map { |r| r[:ca].to_d.round.to_i },
            backgroundColor: stats.map { |r| r[:couleur].presence || rgba_fill(ROSE, 0.85) },
            borderRadius: 4,
            borderWidth: 0,
            barPercentage: 0.7,
            categoryPercentage: 0.8
          }]
        },
        options: {
          indexAxis: "y",
          responsive: true,
          maintainAspectRatio: true,
          aspectRatio: aspect,
          plugins: {
            legend: { display: false },
            title: { display: false }
          },
          scales: {
            x: {
              beginAtZero: true,
              title: { display: true, text: "CA (€)" },
              ticks: { precision: 0 }
            },
            y: {
              ticks: { autoSkip: false }
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
      n = [labels.length, 1].max
      aspect = [[2.4 - (n * 0.08), 1.6].max, 2.4].min

      {
        type: "bar",
        data: {
          labels: labels,
          datasets: [{
            data: values,
            backgroundColor: catalog_bar_colors(values.length),
            borderRadius: 4,
            borderWidth: 0
          }]
        },
        options: {
          indexAxis: "y",
          responsive: true,
          maintainAspectRatio: true,
          aspectRatio: aspect,
          plugins: {
            legend: { display: false },
            title: { display: false }
          },
          scales: {
            x: { beginAtZero: true, ticks: { precision: 0 } }
          }
        }
      }
    end

    def line_chart(title, labels, values, color, integer_ticks: false)
      y_ticks = { precision: 0 }
      {
        type: "line",
        data: {
          labels: labels,
          datasets: [{
            label: title,
            data: values.map { |v| v.nil? ? nil : v.to_d.round.to_i },
            borderColor: color,
            backgroundColor: rgba_fill(color, 0.14),
            fill: true,
            tension: 0.35,
            pointRadius: 2,
            pointHoverRadius: 4,
            pointBackgroundColor: color,
            pointBorderColor: "#fff",
            pointBorderWidth: 1
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: true,
          aspectRatio: 2.4,
          plugins: { legend: { display: false } },
          scales: {
            y: {
              beginAtZero: true,
              ticks: y_ticks
            }
          }
        }
      }
    end

    def mixed_timeline_options(left_title:, right_title:)
      {
        responsive: true,
        maintainAspectRatio: true,
        aspectRatio: 2.4,
        interaction: { mode: "index", intersect: false },
        plugins: {
          legend: { display: true, position: "bottom" }
        },
        scales: {
          y: {
            type: "linear",
            position: "left",
            beginAtZero: true,
            title: { display: true, text: left_title }
          },
          y1: {
            type: "linear",
            position: "right",
            beginAtZero: true,
            grid: { drawOnChartArea: false },
            title: { display: true, text: right_title },
            ticks: { precision: 0 }
          }
        }
      }
    end

    def doughnut_options
      {
        responsive: true,
        maintainAspectRatio: true,
        aspectRatio: 1,
        cutout: "55%",
        plugins: { legend: { position: "bottom" } }
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
      base = [GOLD, "rgb(201, 162, 39)", "rgb(166, 124, 20)", SLATE_SOFT, SLATE]
      Array.new(count) { |i| base[i % base.length] }
    end

    def rgba_fill(rgb, alpha = 0.15)
      m = rgb.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/)
      return rgb unless m

      "rgba(#{m[1]}, #{m[2]}, #{m[3]}, #{alpha})"
    end
  end
end
