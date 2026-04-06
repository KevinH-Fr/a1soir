class Client < ApplicationRecord
    
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

    email = demande.respond_to?(:email) ? demande.email : demande.mail

    # Email + nom combinés : évite les faux positifs pour les couples partageant un email
    if email.present? && demande.nom.present?
      found = find_by(mail: email, nom: demande.nom)
      return found if found
    end

    # Fallback : prénom + nom
    if demande.prenom.present? && demande.nom.present?
      found = where(prenom: demande.prenom, nom: demande.nom).first
      return found if found
    end

    nil
  end
    
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
