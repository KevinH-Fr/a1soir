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
