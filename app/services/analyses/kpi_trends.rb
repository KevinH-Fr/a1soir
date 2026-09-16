# frozen_string_literal: true

module Analyses
  class KpiTrends < ApplicationService
    METRICS_BY_VUE = {
      "synthese" => %i[ca commandes articles_lignes top_vendeur_ca],
      "ca" => %i[ca transactions commandes stripe],
      "catalogue" => %i[quantites ca_lignes produits],
      "equipe" => %i[equipe_ca equipe_commandes equipe_devis]
    }.freeze

    def self.call(filter_params:, vue:, current: nil)
      new(filter_params: filter_params, vue: vue, current: current).call
    end

    def initialize(filter_params:, vue:, current: nil)
      @filter_params = filter_params.to_h.symbolize_keys
      @vue = DashboardVisibility.normalize_vue(vue)
      @current = current
    end

    def call
      range = ComparisonPeriod.previous_range(@filter_params[:debut], @filter_params[:fin])
      return { trends: {}, period_label: nil } if range.nil?

      metrics = METRICS_BY_VUE.fetch(@vue, [])
      current = @current || KpiSnapshot.call(@filter_params, metrics: metrics)

      ref_params = @filter_params.merge(debut: range[:debut], fin: range[:fin])
      if metrics.include?(:top_vendeur_ca)
        profile_id = current[:top_vendeur_profile_id].presence || @filter_params[:top_vendeur_profile_id]
        ref_params = ref_params.merge(top_vendeur_profile_id: profile_id)
      end

      reference = KpiSnapshot.call(ref_params, metrics: metrics)

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
