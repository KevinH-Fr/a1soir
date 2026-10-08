# frozen_string_literal: true

module Analyses
  # Onglet Analyses « Rendez-vous » :
  # - Demandes site (DemandeRdv) : reçues, cabine, statut, type, transformation
  # - Agenda (Meeting) : RDV prévus sur la période, origine site vs interne
  class RdvStats < ApplicationService
    STATUTS = %w[soumis confirmé annulé].freeze

    # Ruby wday : 0=dim … 6=sam — affichage Lun → Dim
    WEEKDAY_ORDER = [1, 2, 3, 4, 5, 6, 0].freeze
    WEEKDAY_LABELS = {
      1 => "Lun", 2 => "Mar", 3 => "Mer", 4 => "Jeu",
      5 => "Ven", 6 => "Sam", 0 => "Dim"
    }.freeze

    def self.call(debut:, fin:)
      new(debut: debut, fin: fin).call
    end

    def initialize(debut:, fin:)
      @debut = debut
      @fin = fin
      @range = period_range
      @grain = TimelineBuckets.grain(@debut, @fin)
    end

    def call
      return empty_result if @range.nil?

      recues = DemandeRdv.where(created_at: @range)
      recues_avec = recues.where.associated(:demande_cabine_essayage)
      recues_sans = recues.where.missing(:demande_cabine_essayage)
      n_recues = recues.count
      n_avec = recues_avec.count
      n_sans = recues_sans.count

      meetings = Meeting.where(datedebut: @range)
      from_site = meetings.where.not(demande_rdv_id: nil)
      interne = meetings.where(demande_rdv_id: nil)

      transformation_stats(recues).merge(
        demandes_recues: n_recues,
        avec_cabine: n_avec,
        sans_cabine: n_sans,
        part_cabine: rate(n_avec, n_recues),
        by_statut: counts_by_statut(recues),
        by_type: counts_by_type(recues),
        timeline_grain: @grain,
        timeline_recues_avec: timeline_counts(recues_avec, "demande_rdvs.created_at"),
        timeline_recues_sans: timeline_counts(recues_sans, "demande_rdvs.created_at"),
        demande_heatmap: demande_heatmap(recues),
        agenda_total: meetings.count,
        agenda_site: from_site.count,
        agenda_interne: interne.count,
        timeline_agenda_site: timeline_counts(from_site, "meetings.datedebut"),
        timeline_agenda_interne: timeline_counts(interne, "meetings.datedebut")
      )
    end

    private

    def period_range
      return nil if @debut.blank? || @fin.blank?

      @debut.beginning_of_day..@fin.end_of_day
    end

    def empty_result
      {
        demandes_recues: 0,
        avec_cabine: 0,
        sans_cabine: 0,
        part_cabine: nil,
        confirmes: 0,
        transformees: 0,
        taux_transformation: nil,
        by_statut: STATUTS.index_with(0),
        by_type: {},
        timeline_grain: :day,
        timeline_recues_avec: {},
        timeline_recues_sans: {},
        demande_heatmap: empty_heatmap,
        agenda_total: 0,
        agenda_site: 0,
        agenda_interne: 0,
        timeline_agenda_site: {},
        timeline_agenda_interne: {}
      }
    end

    def empty_heatmap
      {
        hours: (TimelineBuckets::HOUR_START..TimelineBuckets::HOUR_END).to_a,
        days: WEEKDAY_ORDER.map { |wday| { wday: wday, label: WEEKDAY_LABELS[wday] } },
        counts: {},
        max: 0
      }
    end

    # Heatmap jour × heure sur created_at (date de la demande), timezone app.
    def demande_heatmap(recues)
      counts = Hash.new(0)
      hours_seen = []

      recues.pluck(:created_at).each do |at|
        next if at.blank?

        t = at.in_time_zone
        counts[[t.wday, t.hour]] += 1
        hours_seen << t.hour
      end

      start_h = TimelineBuckets::HOUR_START
      end_h = TimelineBuckets::HOUR_END
      if hours_seen.any?
        start_h = [start_h, hours_seen.min].min
        end_h = [end_h, hours_seen.max].max
      end
      hours = (start_h..end_h).to_a

      {
        hours: hours,
        days: WEEKDAY_ORDER.map { |wday| { wday: wday, label: WEEKDAY_LABELS[wday] } },
        counts: counts,
        max: counts.values.max.to_i
      }
    end

    def counts_by_statut(scope)
      raw = scope.group(:statut).count
      STATUTS.index_with { |statut| raw[statut].to_i }
    end

    def counts_by_type(scope)
      scope.group(:type_rdv).count
           .transform_keys { |code| code.to_s.presence || "—" }
           .sort_by { |label, count| [-count, label] }
           .to_h
    end

    def timeline_counts(scope, qualified_column)
      if @grain == :hour
        rows = scope.pluck(Arel.sql(qualified_column)).compact.map { |at| [at, 1] }
        TimelineBuckets.group_times(rows, grain: :hour).transform_values(&:to_i)
      else
        grouped = scope.group(Arel.sql("DATE(#{qualified_column})")).count
        grouped.transform_keys { |date| TimelineBuckets.normalize_day_key(date) }
      end
    end

    def transformation_stats(recues)
      confirmes = recues.where(statut: "confirmé")
      n_confirmes = confirmes.count
      transformees = transformed_count(confirmes)

      {
        confirmes: n_confirmes,
        transformees: transformees,
        taux_transformation: rate(transformees, n_confirmes)
      }
    end

    def transformed_count(confirmes_scope)
      confirmes_scope
        .joins(:meeting)
        .where.not(meetings: { client_id: nil })
        .where(
          <<~SQL.squish,
            EXISTS (
              SELECT 1 FROM commandes
              WHERE commandes.client_id = meetings.client_id
                AND commandes.devis = ?
                AND commandes.created_at >= meetings.created_at
            )
          SQL
          false
        )
        .distinct
        .count(:id)
    end

    def rate(numerator, denominator)
      return nil if denominator.to_i.zero?

      ((numerator.to_d / denominator) * 100).round(1)
    end
  end
end
