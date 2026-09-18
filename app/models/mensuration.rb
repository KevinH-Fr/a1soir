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

  PHOTO_CONTENT_TYPES = %w[image/jpeg image/jpg image/png image/webp].freeze
  MAX_PHOTO_BYTES = 8.megabytes
  MAX_PHOTO_EDGE = 4000
  IDENTITY_LIMITS = {
    "prenom" => 80,
    "nom" => 80,
    "telephone" => 20,
    "adresse" => 120,
    "cp" => 10,
    "ville" => 80
  }.freeze

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
      key = field["key"]
      next unless values.key?(key)

      case field["input"]
      when "choice"
        values.delete(key) unless field["choices"].include?(values[key])
      when "cm"
        normalized = normalize_cm(values[key], min: field["min"], max: field["max"])
        if normalized
          values[key] = normalized
        else
          values.delete(key)
        end
      when "textarea"
        values[key] = values[key].truncate(field["maxlength"].presence || 400, omission: "")
      else
        limit = field["maxlength"].presence || 40
        values[key] = values[key].truncate(limit, omission: "")
      end
    end

    values.compact_blank!
  end

  def self.normalize_cm(value, min:, max:)
    raw = value.to_s.strip.tr(",", ".")
    return if raw.blank?
    return unless raw.match?(/\A\d{1,3}(\.\d{1,2})?\z/)

    number = Float(raw)
    return if min && number < min.to_f
    return if max && number > max.to_f

    number == number.to_i ? number.to_i.to_s : number.to_s
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

  def apply_public_input(identity:, measurements:, photo: nil, merge: false)
    invitation = mensuration_invitation
    self.template = invitation.template
    self.locale = invitation.locale

    identity_hash = identity.to_h.stringify_keys
    IDENTITY_LIMITS.each do |key, limit|
      next unless identity_hash[key].is_a?(String)

      identity_hash[key] = identity_hash[key].strip.truncate(limit, omission: "")
    end
    identity_hash.compact_blank!
    assign_attributes(identity_hash) if identity_hash.present?

    incoming = self.class.sanitize_measurements(template, measurements)
    self.measurements = if merge
                          (self.measurements || {}).merge(incoming)
                        else
                          incoming
                        end
    self.photo_pied = photo if photo.present?
  end

  def save_draft!(wizard_index:, guide_index: nil)
    self.draft_wizard_index = wizard_index
    self.draft_guide_index = guide_index
    save(validate: false)
  end

  def complete!
    transaction do
      self.draft_wizard_index = nil
      self.draft_guide_index = nil
      return false unless save(context: :complete)

      resolve_and_link_client!
      mensuration_invitation.update!(status: "completed")
      true
    end
  end

  # Rattache au Client dont l'e-mail a déjà été prouvé par OTP.
  # Un changement de nom ne doit pas créer un second client ; une fiche déjà liée reste liée.
  # La fiche client existante n'est jamais écrasée.
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
