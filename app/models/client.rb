class Client < ApplicationRecord

    has_many :commandes
    has_many :meetings

    PROPPART_OPTIONS = ["particuluer", "professionnel"]
    
    def full_name
        prenom + " " + nom
    end
end
