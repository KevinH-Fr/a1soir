class TypeProduit < ApplicationRecord
    has_many :ensembles

    scope :types_enfants_unique, -> { where.not(nom: 'ensemble').distinct }

    def self.ransackable_attributes(auth_object = nil)
        ["created_at", "id", "id_value", "nom", "updated_at"]
    end

end
