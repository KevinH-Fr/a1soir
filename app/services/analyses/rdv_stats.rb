# frozen_string_literal: true

module Analyses
  # Onglet Analyses « Rendez-vous » :
  # - Demandes site (DemandeRdv) : reçues, cabine, statut, type, événement
  # - Agenda (Meeting) : RDV prévus sur la période, origine site vs interne
  # - Transformation : RDV site de la période → commande / en cours / sans commande
  # - CA transformé : encaissé TTC des commandes hors devis liées, une fois par commande
  class RdvStats < ApplicationService
    STATUTS = %w[soumis confirmé annulé].freeze
    EVENEMENT_LABELS = {
      "mariage" => "Mariage",
      "soiree" => "Soirée",
      "soirée" => "Soirée",
      "autre" => "Autre"
    }.freeze
    # Sans commande : « en cours » si le RDV a moins de N jours, sinon « sans ».
    TRANSFORMATION_PENDING_DAYS = 14

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

      transformation_stats(from_site).merge(
        demandes_recues: n_recues,
        avec_cabine: n_avec,
        sans_cabine: n_sans,
        part_cabine: rate(n_avec, n_recues),
        by_statut: counts_by_statut(recues),
        by_type: counts_by_type(recues),
        by_evenement: counts_by_evenement(recues),
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
        transformation_en_cours: 0,
        transformation_sans: 0,
        taux_transformation: nil,
        ca_transformees: 0.to_d,
        by_statut: STATUTS.index_with(0),
        by_type: {},
        by_evenement: {},
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

    HEATMAP_HOURS = (0..23).to_a.freeze

    def empty_heatmap
      {
        hours: HEATMAP_HOURS,
        days: WEEKDAY_ORDER.map { |wday| { wday: wday, label: WEEKDAY_LABELS[wday] } },
        counts: {},
        max: 0
      }
    end

    # Heatmap jour × heure sur created_at (date de la demande), timezone app.
    def demande_heatmap(recues)
      counts = Hash.new(0)

      recues.pluck(:created_at).each do |at|
        next if at.blank?

        t = at.in_time_zone
        counts[[t.wday, t.hour]] += 1
      end

      {
        hours: HEATMAP_HOURS,
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

    def counts_by_evenement(scope)
      totals = Hash.new(0)
      scope.group(:evenement).count.each do |code, count|
        totals[evenement_label(code)] += count.to_i
      end
      totals.sort_by { |label, count| [-count, label] }.to_h
    end

    def evenement_label(code)
      EVENEMENT_LABELS.fetch(code.to_s, code.to_s.presence || "—")
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

    # RDV site (datedebut dans la période) :
    # - transformé : commande hors devis sur la période après le RDV
    # - en cours : pas de commande, RDV < 14 j
    # - sans : pas de commande, RDV ≥ 14 j
    # - CA : encaissé TTC de ces commandes (paiements prix + Stripe − remboursements), sans doublon
    def transformation_stats(site_meetings)
      cohort = site_meetings.where.not(client_id: nil)
      n = cohort.count
      binds = [false, @range.begin, @range.end]
      transformed = cohort.where([period_commande_exists_sql, *binds])
      transformees = transformed.count
      without = cohort.where.not(id: transformed.select(:id))
      pending_after = TRANSFORMATION_PENDING_DAYS.days.ago.end_of_day
      en_cours = without.where("meetings.datedebut > ?", pending_after).count
      sans = without.where("meetings.datedebut <= ?", pending_after).count

      {
        confirmes: n,
        transformees: transformees,
        transformation_en_cours: en_cours,
        transformation_sans: sans,
        taux_transformation: rate(transformees, n),
        ca_transformees: ca_commandes_liees(transformed)
      }
    end

    def ca_commandes_liees(transformed)
      ids = linked_commande_ids(transformed)
      return 0.to_d if ids.empty?

      encaisse = PaiementRecu.only_prix
                             .where(commande_id: ids, moyen: PaiementRecu::MOYEN_PAIEMENT)
                             .sum(:montant).to_d
      stripe = StripePayment.paid.where(commande_id: ids).sum(:amount).to_d / 100
      remboursements = AvoirRemb.remb_only
                                .joins(:commande)
                                .where(commande_id: ids, commandes: { eshop: [false, nil] })
                                .where.not(moyen: [nil, ""])
                                .sum(:montant).to_d
      encaisse + stripe - remboursements
    end

    def linked_commande_ids(transformed)
      Commande.hors_devis
              .joins(<<~SQL.squish)
                INNER JOIN meetings
                  ON meetings.client_id = commandes.client_id
                 AND commandes.created_at >= meetings.datedebut
              SQL
              .where(commandes: { created_at: @range })
              .where(meetings: { id: transformed.reselect(:id) })
              .distinct
              .ids
    end

    def period_commande_exists_sql
      <<~SQL.squish
        EXISTS (
          SELECT 1 FROM commandes
          WHERE commandes.client_id = meetings.client_id
            AND commandes.devis = ?
            AND commandes.created_at >= meetings.datedebut
            AND commandes.created_at >= ?
            AND commandes.created_at <= ?
        )
      SQL
    end

    def rate(numerator, denominator)
      return nil if denominator.to_i.zero?

      ((numerator.to_d / denominator) * 100).round(1)
    end
  end
end
