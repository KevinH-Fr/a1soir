class Mensuration < ApplicationRecord
  belongs_to :mensuration_invitation
  belongs_to :client, optional: true

  # Photo privée (personne identifiable) : jamais servie via les helpers publics
  # cloudinary_attachment_* — voir Admin::MensurationsController#photo.
  has_one_attached :photo_pied

  validates :template, inclusion: { in: MensurationInvitation::TEMPLATES }
  validates :locale, inclusion: { in: %w[fr en] }
  validates :nom, presence: true
  validates :prenom, presence: true
  validate :photo_pied_must_be_image

  PHOTO_CONTENT_TYPES = %w[image/jpeg image/jpg image/png image/webp].freeze
  MAX_PHOTO_BYTES = 8.megabytes
  MAX_PHOTO_EDGE = 4000

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

  def apply_public_input(identity:, measurements:, photo: nil)
    invitation = mensuration_invitation
    self.template = invitation.template
    self.locale = invitation.locale
    assign_attributes(identity)
    self.measurements = self.class.sanitize_measurements(template, measurements)
    self.photo_pied = photo if photo.present?
  end

  def complete!
    transaction do
      return false unless save

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
