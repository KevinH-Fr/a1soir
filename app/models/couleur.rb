class Couleur < ApplicationRecord
    has_many :produits

    def self.ransackable_attributes(auth_object = nil)
        ["created_at", "id", "id_value", "nom", "updated_at"]
    end

end
