class TypeProduit < ApplicationRecord
    has_many :ensembles

    before_validation :downcase_nom
    validates :nom, presence: true, uniqueness: { case_sensitive: false }

    scope :types_enfants_unique, -> { where.not(nom: 'ensemble').distinct }

    def hard_destroy_allowed?
      return false if Produit.exists?(type_produit_id: id)
      return false if Ensemble.where(
        "type_produit1_id = :id OR type_produit2_id = :id OR type_produit3_id = :id OR " \
        "type_produit4_id = :id OR type_produit5_id = :id OR type_produit6_id = :id",
        id: id
      ).exists?

      true
    end

    def self.ransackable_attributes(auth_object = nil)
        ["created_at", "id", "id_value", "nom", "updated_at"]
    end

    private
  
    def downcase_nom
      self.nom = nom.downcase if nom.present?
    end
    
end
