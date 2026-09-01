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

  MAX_PHOTO_BYTES = 15.megabytes

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

  # Valeur saisie pour une clé de mesure (JSON à clés stables).
  def value_for(key)
    (measurements || {})[key.to_s]
  end

  # Rattache au Client existant (mail + nom stricts, comme l'e-shop) sans toucher sa fiche ;
  # sinon crée un client minimal depuis les coordonnées saisies.
  def resolve_and_link_client!
    invitation = mensuration_invitation
    client = Client.find_existing_for_public_contact(
      email: invitation.email, nom: nom, prenom: prenom, use_prenom_nom_fallback: false
    )
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

    unless photo_pied.content_type.to_s.start_with?("image/")
      errors.add(:photo_pied, :invalid)
    end
    if photo_pied.byte_size > MAX_PHOTO_BYTES
      errors.add(:photo_pied, :too_large)
    end
  end
end
