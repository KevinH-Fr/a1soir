class CategorieProduit < ApplicationRecord
    has_many :produits

    def self.ransackable_attributes(auth_object = nil)
        ["nom"]
    end

end
