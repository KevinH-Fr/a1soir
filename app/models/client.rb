class Client < ApplicationRecord

    has_many :commandes
    
    def full_name
        prenom + " " + nom
    end
end
