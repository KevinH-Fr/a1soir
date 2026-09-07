class Mensuration < ApplicationRecord
  belongs_to :mensuration_invitation
  belongs_to :client, optional: true

  # Photo privée (personne identifiable) : jamais servie via les helpers publics
  # cloudinary_attachment_* — voir Admin::MensurationsController#photo.
  has_one_attached :photo_pied

  validates :template, inclusion: { in: MensurationInvitation::TEMPLATES }
  validates :locale, inclusion: { in: %w[fr en] }
  validates :nom, presence: true, on: :complete
  validates :prenom, presence: true, on: :complete
  validate :photo_pied_must_be_image, on: :complete
  validate :identity_step_fields, on: :identity_step
  validate :measure_step_required_fields, on: :measure_step
  validate :all_required_measurements, on: :complete

  PHOTO_CONTENT_TYPES = %w[image/jpeg image/jpg image/png image/webp].freeze
  MAX_PHOTO_BYTES = 8.megabytes
  MAX_PHOTO_EDGE = 4000

  scope :pending_admin, -> { where(admin_treated_at: nil) }
  scope :pending_admin_received, -> {
    pending_admin.joins(:mensuration_invitation).merge(MensurationInvitation.admin_received)
  }

  def self.ransackable_attributes(_auth_object = nil)
    %w[nom prenom]
  end

  def admin_treated?
    admin_treated_at.present?
  end

  def mark_admin_treated!
    update!(admin_treated_at: Time.current)
  end

  # Jeux de champs par template (femme/homme n'ont pas les mêmes mesures — cf. PDF papier).
  def self.fields_for(template)
    all_fields.fetch(template.to_s, [])
  end

  def self.field_keys_for(template)
    fields_for(template).map { |field| field["key"] }
  end

  # Clés du YAML + valeurs de liste prévues ; le reste est ignoré.
  def self.sanitize_measurements(template, raw)
    fields = fields_for(template)
    allowed = fields.map { |field| field["key"] }
    values = raw.to_h.stringify_keys.slice(*allowed)
    values.transform_values! { |value| value.to_s.strip }
    values.compact_blank!

    fields.each do |field|
      next unless field["input"] == "choice"

      key = field["key"]
      values.delete(key) unless field["choices"].include?(values[key])
    end

    values
  end

  def self.all_fields
    @all_fields ||= YAML.load_file(Rails.root.join("config/mensuration_fields.yml"))
  end

  def fields
    self.class.fields_for(template)
  end

  # Volets du wizard (ordre YAML). Femme : un volet ; homme : tailles puis corps.
  def fields_by_form_step
    fields.group_by { |field| field["step"].presence || "mesures" }
  end

  # Valeur saisie pour une clé de mesure (JSON à clés stables).
  def value_for(key)
    (measurements || {})[key.to_s]
  end

  # Changement femme/homme : on ne garde que les mesures du nouveau jeu.
  def apply_template!(template)
    allowed = self.class.field_keys_for(template)
    update!(template: template, measurements: (measurements || {}).slice(*allowed))
  end

  def assign_identity(attrs)
    invitation = mensuration_invitation
    self.template = invitation.template
    self.locale = invitation.locale

    identity_hash = attrs.to_h.stringify_keys.compact_blank
    assign_attributes(identity_hash) if identity_hash.present?
  end

  def merge_measurements(raw)
    incoming = self.class.sanitize_measurements(template, raw)
    self.measurements = (measurements || {}).merge(incoming)
  end

  def save_step!(flow_step, identity: nil, measurements: nil, advance_to: nil)
    invitation = mensuration_invitation
    self.template = invitation.template
    self.locale = invitation.locale

    case flow_step.kind
    when :identity
      assign_identity(identity)
    when :measure_clip, :measure_group
      merge_measurements(measurements) if measurements.present?
    end

    @validating_step = flow_step
    return false unless valid?(flow_step.validation_context)

    self.draft_step = advance_to.presence || flow_step.key
    save(validate: false)
  end

  def apply_complete_input(photo: nil)
    self.photo_pied = photo if photo.present?
  end

  def complete!
    transaction do
      self.draft_step = nil
      return false unless save(context: :complete)

      resolve_and_link_client!
      mensuration_invitation.update!(status: "completed")
      true
    end
  end

  # Rattache au Client dont l'e-mail a déjà été prouvé par OTP.
  def resolve_and_link_client!
    invitation = mensuration_invitation
    client = self.client || invitation.client ||
             Client.find_existing_by_verified_email(invitation.email)
    client ||= Client.create!(
      intitule: template == "homme" ? "Monsieur" : "Madame",
      prenom: prenom, nom: nom, tel: telephone, mail: invitation.email,
      adresse: adresse, cp: cp, ville: ville, language: locale
    )
    update!(client: client)
    invitation.update!(client: client)
    client
  end

  private

  def identity_step_fields
    errors.add(:prenom, :blank) if prenom.blank?
    return if nom.present? || mensuration_invitation.nom.present?

    errors.add(:nom, :blank)
  end

  def measure_step_required_fields
    return unless @validating_step

    validate_required_field_keys(@validating_step.field_keys)
  end

  def all_required_measurements
    validate_required_field_keys(fields.select { |f| f["required"] }.map { |f| f["key"] })
  end

  def validate_required_field_keys(keys)
    keys.each do |key|
      field = fields.find { |f| f["key"] == key }
      next unless field&.fetch("required", false)

      if value_for(key).blank?
        errors.add(:base, I18n.t("mensurations.form.required_field",
                                 field: I18n.t("mensurations.fields.#{key}.short")))
      end
    end
  end

  def photo_pied_must_be_image
    return unless photo_pied.attached?

    unless PHOTO_CONTENT_TYPES.include?(photo_pied.content_type.to_s)
      errors.add(:photo_pied, I18n.t("mensurations.photo.invalid_format"))
      return
    end
    if photo_pied.byte_size > MAX_PHOTO_BYTES
      errors.add(:photo_pied, I18n.t("mensurations.photo.too_large", max_mb: MAX_PHOTO_BYTES / 1.megabyte))
      return
    end

    width, height = photo_dimensions
    return if width.zero? || height.zero?

    if [width, height].max > MAX_PHOTO_EDGE
      errors.add(:photo_pied, I18n.t("mensurations.photo.too_big", max_px: MAX_PHOTO_EDGE))
    end
  end

  def photo_dimensions
    blob = photo_pied.blob
    blob.analyze unless blob.analyzed?
    [blob.metadata["width"].to_i, blob.metadata["height"].to_i]
  rescue StandardError
    [0, 0]
  end
end
