# frozen_string_literal: true

module Analyses
  class KpiTrends < ApplicationService
    METRICS_BY_VUE = {
      "synthese" => %i[ca commandes articles_lignes devis],
      "ca" => %i[ca transactions commandes stripe],
      "catalogue" => %i[quantites ca_lignes produits],
      "equipe" => %i[equipe_ca equipe_commandes equipe_devis]
    }.freeze

    def self.call(filter_params:, vue:)
      new(filter_params: filter_params, vue: vue).call
    end

    def initialize(filter_params:, vue:)
      @filter_params = filter_params.to_h.symbolize_keys
      @vue = DashboardVisibility.normalize_vue(vue)
    end

    def call
      range = ComparisonPeriod.previous_range(@filter_params[:debut], @filter_params[:fin])
      return { trends: {}, period_label: nil } if range.nil?

      current = KpiSnapshot.call(@filter_params)
      reference = KpiSnapshot.call(
        @filter_params.merge(debut: range[:debut], fin: range[:fin])
      )

      metrics = METRICS_BY_VUE.fetch(@vue, [])
      trends = metrics.index_with do |key|
        build_trend(current[key], reference[key], range[:label])
      end

      { trends: trends, period_label: range[:label] }
    end

    private

    def build_trend(current, previous, period_label)
      curr = current.to_d
      prev = previous.to_d

      if prev.zero?
        return { pct: nil, direction: :neutral, period_label: period_label }
      end

      change = ((curr - prev) / prev * 100).round(1)
      direction = if change.positive?
                    :up
                  elsif change.negative?
                    :down
                  else
                    :neutral
                  end

      { pct: change.abs, signed_pct: change, direction: direction, period_label: period_label }
    end
  end
end
