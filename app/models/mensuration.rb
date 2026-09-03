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
  MIN_PHOTO_EDGE = 400

  # Jeux de champs par template (femme/homme n'ont pas les mêmes mesures — cf. PDF papier).
  def self.fields_for(template)
    all_fields.fetch(template.to_s, [])
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
    elsif [width, height].min < MIN_PHOTO_EDGE
      errors.add(:photo_pied, I18n.t("mensurations.photo.too_small", min_px: MIN_PHOTO_EDGE))
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
