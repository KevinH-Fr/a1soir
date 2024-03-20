class Fournisseur < ApplicationRecord
    validates :nom, presence: true

    def self.ransackable_attributes(auth_object = nil)
        ["contact", "created_at", "id", "id_value", "mail", "nom", "notes", "site", "tel", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
        []
    end

end
