# frozen_string_literal: true

module Analyses
  # Grain et labels des timelines Analyses (jour vs heure, timezone Paris).
  # Ne jamais grouper l'heure via strftime SQL UTC — passer par Time.zone.
  class TimelineBuckets
    HOUR_START = 8
    HOUR_END = 20

    class << self
      def grain(debut, fin)
        return :day if debut.blank? || fin.blank?

        debut.to_date == fin.to_date ? :hour : :day
      end

      def day_label(date)
        I18n.l(date.to_date, format: "%d/%m/%Y")
      end

      def hour_label(time)
        "#{time.in_time_zone.hour}h"
      end

      def label_for(time_or_date, grain:)
        grain.to_sym == :hour ? hour_label(time_or_date) : day_label(time_or_date)
      end

      # [[time, amount], ...] → { "10h" => sum } ou { "19/09/2026" => sum }
      def group_times(rows, grain:)
        merged = Hash.new(0.to_d)
        Array(rows).each do |time, amount|
          next if time.blank?

          label = label_for(time, grain: grain)
          merged[label] += amount.to_d
        end
        sort_hash(merged, grain: grain)
      end

      def sort_hash(hash, grain: :day)
        return {} if hash.blank?

        hash.sort_by { |label, _| sort_key(label, grain: grain) }.to_h
      end

      def sort_key(label, grain: :day)
        if grain.to_sym == :hour
          label.to_s.delete_suffix("h").to_i
        else
          Date.strptime(label.to_s, "%d/%m/%Y")
        end
      rescue ArgumentError
        label.to_s
      end

      # Remplit les buckets vides pour l'axe X.
      # Heure : 8h → maintenant (si aujourd'hui) ou → 20h ; étend si données hors plage ; pas d'heures futures.
      # Jour : tous les jours de [debut, fin].
      def filled_labels(debut:, fin:, grain:, data_keys: [], now: Time.zone.now)
        keys = Array(data_keys).map(&:to_s)
        if grain.to_sym == :hour
          filled_hour_labels(debut: debut, data_keys: keys, now: now)
        else
          filled_day_labels(debut: debut, fin: fin, data_keys: keys)
        end
      end

      def normalize_day_key(date_key)
        day_label(Date.parse(date_key.to_s))
      rescue ArgumentError, TypeError
        date_key.to_s
      end

      private

      def filled_day_labels(debut:, fin:, data_keys:)
        if debut.present? && fin.present?
          (debut.to_date..fin.to_date).map { |d| day_label(d) }
        else
          data_keys.uniq.sort_by { |label| sort_key(label, grain: :day) }
        end
      end

      def filled_hour_labels(debut:, data_keys:, now:)
        day = (debut.presence || now).to_date
        current = now.in_time_zone
        end_hour = if day == current.to_date
                     current.hour
                   else
                     HOUR_END
                   end

        start_h = HOUR_START
        end_h = [end_hour, HOUR_START].max

        data_hours = data_keys.filter_map { |k| k.to_s[/\A(\d{1,2})h\z/, 1]&.to_i }
        start_h = [start_h, *data_hours].min if data_hours.any?
        end_h = [end_h, *data_hours].max if data_hours.any?
        end_h = [end_h, 23].min

        (start_h..end_h).map { |h| "#{h}h" }
      end
    end
  end
end
