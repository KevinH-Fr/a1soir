class CategorieProduit < ApplicationRecord
    has_many :produits

    before_validation :downcase_nom
    validates :nom, presence: true, uniqueness: { case_sensitive: false }

    def self.ransackable_attributes(auth_object = nil)
        ["nom"]
    end

    private

    def downcase_nom
        self.nom = nom.downcase if nom.present?
    end

end
