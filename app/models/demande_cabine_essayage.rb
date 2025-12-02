class DemandeCabineEssayage < ApplicationRecord
    belongs_to :demande_rdv, optional: true
    
    has_many :demande_cabine_essayage_items, dependent: :destroy
    has_many :produits, through: :demande_cabine_essayage_items
  
    accepts_nested_attributes_for :demande_cabine_essayage_items, allow_destroy: true
      
    # Validations
    validate :has_at_least_one_item

    # Ransackable attributes for admin search
    def self.ransackable_attributes(auth_object = nil)
      ["created_at", "demande_rdv_id", "id", "id_value", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      ["demande_cabine_essayage_items", "demande_rdv", "produits"]
    end

  private

  def has_at_least_one_item
    if demande_cabine_essayage_items.size == 0
      errors.add(:demande_cabine_essayage_items, "doit contenir au moins un produit")
    end
  end
end
  