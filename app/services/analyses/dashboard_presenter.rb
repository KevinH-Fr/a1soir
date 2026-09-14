# frozen_string_literal: true

module Analyses
  # Assigne les ivars du controller selon l'onglet actif (évite calculs inutiles).
  class DashboardPresenter
    def initialize(controller, scopes:, filter_params:, stripe_totals:)
      @controller = controller
      @scopes = scopes
      @filter_params = filter_params
      @stripe_totals = stripe_totals
      @datedebut = scopes[:datedebut]
      @datefin = scopes[:datefin]
    end

    def call(vue:)
      vue = DashboardVisibility.normalize_vue(vue)

      case vue
      when "synthese"
        assign_synthese
      when "ca"
        assign_ca_tab
      when "catalogue"
        assign_catalogue
      when "equipe"
        assign_equipe
      end
    end

    private

    def assign_synthese
      c.send(:assign_commande_metrics)
      c.send(:assign_article_metrics)
      c.send(:assign_ca_metrics, @stripe_totals, @datedebut, @datefin)
    end

    def assign_ca_tab
      c.send(:assign_commande_metrics)
      c.send(:assign_ca_metrics, @stripe_totals, @datedebut, @datefin)
      c.send(:assign_transaction_metrics, @stripe_totals, @datedebut, @datefin)
    end

    def assign_catalogue
      c.send(:assign_article_metrics)
      c.send(:assign_catalog_stats)
    end

    def assign_equipe
      c.send(:assign_profile_stats, @datedebut, @datefin, @stripe_totals, @filter_params)
    end

    def c
      @controller
    end
  end
end
