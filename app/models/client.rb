class Client < ApplicationRecord

    def full_name
        prenom + " " + nom
    end
end
