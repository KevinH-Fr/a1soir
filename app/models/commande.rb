class Commande < ApplicationRecord
    belongs_to :client


    scope :client_courant, ->  (client_courant) { where("client_id = ?", client_courant)}

    def full_name
        "n°#{id} | #{nom}"
    end

end
