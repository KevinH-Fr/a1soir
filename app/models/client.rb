class Client < ApplicationRecord
    # Même forme qu’en base pour les recherches : find_by(mail: …) sans SQL LOWER.
    normalizes :mail, with: ->(mail) { mail.to_s.strip.downcase.presence }

    before_validation :capitalize_names

    has_many :commandes
    has_many :meetings
    
    validates :nom, presence: true
    validate :tel_or_mail_present
  
    PROPART_OPTIONS = ["particulier", "professionnel"]
    INTITULE_OPTIONS = ["Madame", "Monsieur", "Madame et Monsieur"]
    
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

  def self.find_existing_from_demande(demande)
    # Priorité : email + nom (combinés) > prénom + nom
    # Le téléphone n'est pas utilisé comme critère : trop peu fiable (valeurs corrompues, numéros partagés).
    # Mail : même normalisation qu’en base (normalizes :mail) → where simple, pas de LOWER SQL.
    # Nom / prénom : String#casecmp? (insensible à la casse), espaces gérés avec strip.

    email = demande.respond_to?(:email) ? demande.email : demande.mail

    if email.present? && demande.nom.present?
      found = find_by_normalized_mail_and_nom(email, demande.nom)
      return found if found
    end

    if demande.prenom.present? && demande.nom.present?
      found = find_by_normalized_prenom_and_nom(demande.prenom, demande.nom)
      return found if found
    end

    nil
  end

  def self.normalize_mail_for_lookup(value)
    value.to_s.strip.downcase.presence
  end
  private_class_method :normalize_mail_for_lookup

  def self.find_by_normalized_mail_and_nom(mail, nom)
    m = normalize_mail_for_lookup(mail)
    n = nom.to_s.strip
    return nil if m.blank? || n.blank?

    where(mail: m).find { |c| c.nom.to_s.strip.casecmp?(n) }
  end
  private_class_method :find_by_normalized_mail_and_nom

  # Secours si le mail n’a pas permis de trancher : parcourt les clients (cas rare).
  def self.find_by_normalized_prenom_and_nom(prenom, nom)
    p = prenom.to_s.strip
    n = nom.to_s.strip
    return nil if p.blank? || n.blank?

    find_each do |c|
      next if c.prenom.blank? || c.nom.blank?

      return c if c.prenom.strip.casecmp?(p) && c.nom.strip.casecmp?(n)
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
