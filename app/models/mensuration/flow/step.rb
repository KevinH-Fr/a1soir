class Mensuration::Flow::Step
      KINDS = %i[identity measure_clip measure_group photo].freeze

      attr_reader :key, :kind, :field_keys, :partial, :form_step_key, :fields
      attr_accessor :position

      def initialize(key:, kind:, field_keys:, partial:, form_step_key: nil, fields: [])
        @key = key
        @kind = kind
        @field_keys = field_keys
        @partial = partial
        @form_step_key = form_step_key
        @fields = fields
        @position = position
      end

      def validation_context
        case kind
        when :identity then :identity_step
        when :measure_clip, :measure_group then :measure_step
        when :photo then :photo_step
        end
      end

      def first?
        position == 1
      end

      def photo?
        kind == :photo
      end

      def title_key
        return "mensurations.form.identity_title" if kind == :identity
        return "mensurations.form.photo_title" if kind == :photo

        "mensurations.form.#{form_step_key}_title"
      end

      def hint_key
        return nil if kind == :identity || kind == :photo

        "mensurations.form.#{form_step_key}_hint"
      end
    end
