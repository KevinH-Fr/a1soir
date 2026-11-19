# frozen_string_literal: true

module Analyses
  # Devis devenus commandes.
  # - transformes : converti_le dans la période (le devis peut avoir été créé avant)
  # - taux : part déjà convertie parmi les devis créés dans la période
  class DevisTransformation < ApplicationService
    TYPES = %w[vente location mixte].freeze

    def self.call(datedebut:, datefin:, profile_id: nil)
      new(datedebut: datedebut, datefin: datefin, profile_id: profile_id).call
    end

    def initialize(datedebut:, datefin:, profile_id: nil)
      @datedebut = datedebut
      @datefin = datefin
      @profile_id = profile_id
    end

    def call
      par_type = empty_par_type
      transformes_scope.group(:type_locvente).count.each do |type, count|
        par_type[type] = count if TYPES.include?(type)
      end

      cohorte = cohorte_scope.count
      cohorte_transformes = cohorte_transformes_scope.count

      {
        transformes: transformes_scope.count,
        par_type: par_type,
        cohorte: cohorte,
        cohorte_transformes: cohorte_transformes,
        taux: rate(cohorte_transformes, cohorte),
        by_profile: by_profile
      }
    end

    private

    def base_scope
      scope = Commande.all
      scope = scope.where(profile_id: @profile_id) if @profile_id.present?
      scope
    end

    def transformes_scope
      scope = base_scope.hors_devis.where.not(converti_le: nil)
      return scope unless period?

      scope.where("commandes.converti_le >= ? AND commandes.converti_le <= ?", period_start, period_end)
    end

    def cohorte_scope
      scope = base_scope.where("commandes.devis = ? OR commandes.converti_le IS NOT NULL", true)
      return scope unless period?

      scope.where("commandes.created_at >= ? AND commandes.created_at <= ?", period_start, period_end)
    end

    def cohorte_transformes_scope
      cohorte_scope.hors_devis.where.not(converti_le: nil)
    end

    def by_profile
      buckets = {}

      transformes_scope.group(:profile_id, :type_locvente).count.each do |(profile_id, type), count|
        bucket = bucket_for(buckets, profile_id)
        bucket[:transformes] += count
        bucket[:par_type][type] = count if TYPES.include?(type)
      end

      cohorte_scope.group(:profile_id).count.each do |profile_id, count|
        bucket_for(buckets, profile_id)[:cohorte] = count
      end

      cohorte_transformes_scope.group(:profile_id).count.each do |profile_id, count|
        bucket_for(buckets, profile_id)[:cohorte_transformes] = count
      end

      cohorte_transformes_scope.group(:profile_id, :type_locvente).count.each do |(profile_id, type), count|
        bucket = bucket_for(buckets, profile_id)
        bucket[:cohorte_par_type][type] = count if TYPES.include?(type)
      end

      buckets.each_value do |bucket|
        bucket[:taux] = rate(bucket[:cohorte_transformes], bucket[:cohorte])
      end
      buckets
    end

    def bucket_for(buckets, profile_id)
      buckets[profile_id] ||= {
        transformes: 0,
        par_type: empty_par_type,
        cohorte: 0,
        cohorte_par_type: empty_par_type,
        cohorte_transformes: 0,
        taux: nil
      }
    end

    def empty_par_type
      TYPES.index_with(0)
    end

    def period?
      @datedebut.present? && @datefin.present?
    end

    def period_start
      @datedebut.beginning_of_day
    end

    def period_end
      @datefin.end_of_day
    end

    def rate(numerator, denominator)
      return nil if denominator.to_i.zero?

      ((numerator.to_d / denominator) * 100).round
    end
  end
end
