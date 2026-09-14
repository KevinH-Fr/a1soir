# frozen_string_literal: true

module Analyses
  # Période de référence immédiatement avant [debut, fin], même nombre de jours.
  class ComparisonPeriod
    def self.previous_range(debut, fin)
      new(debut, fin).previous_range
    end

    def initialize(debut, fin)
      @debut = debut&.to_date
      @fin = fin&.to_date
    end

    def previous_range
      return nil if @debut.nil? || @fin.nil?
      return nil if @fin < @debut

      length_days = (@fin - @debut).to_i + 1
      ref_fin = @debut - 1.day
      ref_debut = ref_fin - (length_days - 1).days

      {
        debut: ref_debut,
        fin: ref_fin,
        label: comparison_label(length_days)
      }
    end

    private

    def comparison_label(length_days)
      if length_days == 1
        "vs veille"
      else
        "vs #{length_days} j. préc."
      end
    end
  end
end
