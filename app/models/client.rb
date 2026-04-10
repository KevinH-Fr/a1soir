class Client < ApplicationRecord
    # Même forme qu’en base pour les recherches : find_by(mail: …) sans SQL LOWER.
    normalizes :mail, with: ->(mail) { mail.to_s.strip.downcase.presence }

    before_validation :capitalize_names

    has_many :commandes
    has_many :meetings
    
    validates :nom, presence: true
    validate :tel_or_mail_present
  
    PROPART_OPTIONS = ["particulier", "professionnel"]
    INTITULE_OPTIONS = ["Madame", "Monsieur", "Madame et Monsieur", "Madame/Monsieur"]
    ESHOP_DEFAULT_INTITULE = "Madame/Monsieur"
    
    def full_name
      prenom + " " + nom
    end

    def full_intitule
      if propart == "professionnel"
        nom
      else
        "#{intitule} #{nom}"
      end 
    end

    def next_upcoming_meeting
        meetings.where('datedebut > ?', Time.now).order(datedebut: :asc).first
      end
      
    def self.ransackable_attributes(auth_object = nil)
        ["adresse", "commentaires", "contact", "cp", "created_at", "id", "id_value", "intitule", "mail", "mail2", "nom", "pays", "prenom", "propart", "tel", "tel2", "updated_at", "ville"]
    end

    def self.ransackable_associations(auth_object = nil)
        ["commandes", "meetings"]
    end

    def language_label
      case language
      when 'fr' then 'Français'
      when 'en' then 'Anglais'
      else language
      end
    end

  def self.create_from_demande(demande)
    # Retourne un client correspondant à la demande.
    # Si un client existe déjà, on le renvoie tel quel (les données client restent sous contrôle de l'admin).
    # Sinon, on instancie un nouveau client à partir des attributs fournis par la demande.
    existing = find_existing_from_demande(demande)
    return [existing, false] if existing

    client = new(demande.to_client_attributes)
    [client, client.save]
  end

  # Exposée pour l’e-shop (Stripe) et tout autre flux public.
  # Priorité : e-mail normalisé + nom ; optionnellement repli prénom + nom (RDV avec mail ambigu).
  # L’e-shop doit appeler avec use_prenom_nom_fallback: false : le placeholder « Client / E-shop » ne doit pas
  # collisionner avec un autre client via le repli sans e-mail.
  def self.find_existing_for_public_contact(email:, nom:, prenom:, use_prenom_nom_fallback: true)
    if email.present? && nom.present?
      found = find_by_normalized_mail_and_nom(email, nom)
      return found if found
    end

    if use_prenom_nom_fallback && prenom.present? && nom.present?
      found = find_by_normalized_prenom_and_nom(prenom, nom)
      return found if found
    end

    nil
  end

  def self.find_existing_from_demande(demande)
    email = demande.respond_to?(:email) ? demande.email : demande.mail
    find_existing_for_public_contact(
      email: email,
      nom: demande.nom,
      prenom: demande.prenom,
      use_prenom_nom_fallback: true
    )
  end

  def self.normalize_mail_for_lookup(value)
    value.to_s.strip.downcase.presence
  end
  private_class_method :normalize_mail_for_lookup

  # Insensible à la casse ; espaces / tirets équivalents (ex. "E-shop" vs "E Shop" après titleize).
  def self.normalize_name_for_lookup(value)
    value.to_s.strip.downcase.gsub(/[-\s]+/, " ").squeeze(" ").presence
  end
  private_class_method :normalize_name_for_lookup

  def self.find_by_normalized_mail_and_nom(mail, nom)
    m = normalize_mail_for_lookup(mail)
    n_key = normalize_name_for_lookup(nom)
    return nil if m.blank? || n_key.blank?

    where(mail: m).find { |c| normalize_name_for_lookup(c.nom) == n_key }
  end
  private_class_method :find_by_normalized_mail_and_nom

  # Secours si le mail n’a pas permis de trancher : parcourt les clients (cas rare).
  def self.find_by_normalized_prenom_and_nom(prenom, nom)
    p_key = normalize_name_for_lookup(prenom)
    n_key = normalize_name_for_lookup(nom)
    return nil if p_key.blank? || n_key.blank?

    find_each do |c|
      next if c.prenom.blank? || c.nom.blank?

      next unless normalize_name_for_lookup(c.prenom) == p_key && normalize_name_for_lookup(c.nom) == n_key

      return c
    end
    nil
  end
  private_class_method :find_by_normalized_prenom_and_nom

    private
  
    def capitalize_names
      self.prenom = prenom.titleize if prenom.present?
      self.nom = nom.titleize if nom.present?
    end

    def tel_or_mail_present
        unless tel.present? || mail.present?
          errors.add(:base, "Remplir le téléphone ou le mail")
        end
    end

end
