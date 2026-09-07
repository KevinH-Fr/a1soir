class Mensuration::Flow
    IDENTITY = "identity".freeze
    PHOTO = "photo".freeze

    def initialize(invitation, mensuration)
      @invitation = invitation
      @mensuration = mensuration
      @template = invitation.template.to_s
    end

    def steps
      @steps ||= build_steps
    end

    def step(key = nil)
      resolved = resolve_key(key)
      steps.find { |s| s.key == resolved } || steps.first
    end

    def next(step)
      index = steps.index { |s| s.key == step.key }
      return nil unless index

      steps[index + 1]
    end

    def previous(step)
      index = steps.index { |s| s.key == step.key }
      return nil unless index&.positive?

      steps[index - 1]
    end

    def position(step)
      step.position
    end

    def total
      steps.size
    end

    def resume_key
      steps.find { |s| s.key == @mensuration.draft_step }&.key || steps.first&.key
    end

    private

    def resolve_key(key)
      return key if key.present? && steps.any? { |s| s.key == key }

      resume_key
    end

    def build_steps
      list = [identity_step]
      list.concat(measure_steps)
      list << photo_step
      list.each_with_index { |step, index| step.position = index + 1 }
      list
    end

    def identity_step
      Step.new(
        key: IDENTITY,
        kind: :identity,
        field_keys: [],
        partial: "identity"
      )
    end

    def photo_step
      Step.new(
        key: PHOTO,
        kind: :photo,
        field_keys: [],
        partial: "photo"
      )
    end

    def measure_steps
      case @template
      when "femme" then femme_measure_steps
      when "homme" then homme_measure_steps
      else []
      end
    end

    def femme_measure_steps
      fields = Mensuration.fields_for("femme")
      clip_fields = fields.select { |f| f["clip"].present? }
      plain_fields = fields.reject { |f| f["clip"].present? }

      steps = clip_fields.map do |field|
        Step.new(
          key: "mesures.#{field["key"]}",
          kind: :measure_clip,
          field_keys: [field["key"]],
          partial: "measure_clip",
          form_step_key: "mesures",
          fields: [field]
        )
      end

      if plain_fields.any?
        steps << Step.new(
          key: "mesures.vetements",
          kind: :measure_group,
          field_keys: plain_fields.map { |f| f["key"] },
          partial: "measure_group",
          form_step_key: "mesures",
          fields: plain_fields
        )
      end

      steps
    end

    def homme_measure_steps
      fields = Mensuration.fields_for("homme")
      steps = []

      tailles = fields.select { |f| f["step"] == "tailles" }
      if tailles.any?
        steps << Step.new(
          key: "tailles",
          kind: :measure_group,
          field_keys: tailles.map { |f| f["key"] },
          partial: "measure_group",
          form_step_key: "tailles",
          fields: tailles
        )
      end

      fields.select { |f| f["step"] == "corps" && f["clip"].present? }.each do |field|
        steps << Step.new(
          key: "corps.#{field["key"]}",
          kind: :measure_clip,
          field_keys: [field["key"]],
          partial: "measure_clip",
          form_step_key: "corps",
          fields: [field]
        )
      end

      steps
    end
  end
