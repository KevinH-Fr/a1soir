class Client < ApplicationRecord

    has_many :commandes
    has_many :meetings
    
    def full_name
        prenom + " " + nom
    end
end
