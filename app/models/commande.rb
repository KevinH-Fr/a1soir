class Commande < ApplicationRecord
    belongs_to :client


    def full_name
        "n°#{id} | #{nom}"
    end

end
