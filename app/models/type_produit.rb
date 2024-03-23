class TypeProduit < ApplicationRecord
    has_many :ensembles

    before_validation :downcase_nom
    validates :nom, presence: true, uniqueness: { case_sensitive: false }

    scope :types_enfants_unique, -> { where.not(nom: 'ensemble').distinct }

    def self.ransackable_attributes(auth_object = nil)
        ["created_at", "id", "id_value", "nom", "updated_at"]
    end

    private
  
    def downcase_nom
      self.nom = nom.downcase if nom.present?
    end
    
end
