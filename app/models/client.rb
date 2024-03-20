class Client < ApplicationRecord

    has_many :commandes
    has_many :meetings

    PROPART_OPTIONS = ["particuluer", "professionnel"]
    
    def full_name
        prenom + " " + nom
    end

    def self.ransackable_attributes(auth_object = nil)
        ["adresse", "commentaires", "contact", "cp", "created_at", "id", "id_value", "intitule", "mail", "mail2", "nom", "pays", "prenom", "propart", "tel", "tel2", "updated_at", "ville"]
    end

    def self.ransackable_associations(auth_object = nil)
        ["commandes", "meetings"]
    end

end
