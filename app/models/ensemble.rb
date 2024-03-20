class Ensemble < ApplicationRecord
    belongs_to :produit

    belongs_to :type_produit1, class_name: 'TypeProduit', foreign_key: 'type_produit1_id', optional: true
    belongs_to :type_produit2, class_name: 'TypeProduit', foreign_key: 'type_produit2_id', optional: true
    belongs_to :type_produit3, class_name: 'TypeProduit', foreign_key: 'type_produit3_id', optional: true
    belongs_to :type_produit4, class_name: 'TypeProduit', foreign_key: 'type_produit4_id', optional: true
    belongs_to :type_produit5, class_name: 'TypeProduit', foreign_key: 'type_produit5_id', optional: true
    belongs_to :type_produit6, class_name: 'TypeProduit', foreign_key: 'type_produit6_id', optional: true
  
    def self.ransackable_attributes(auth_object = nil)
      ["created_at", "id", "id_value", "produit_id", "type_produit1_id", "type_produit2_id", "type_produit3_id", "type_produit4_id", "type_produit5_id", "type_produit6_id", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      ["produit", "type_produit1", "type_produit2", "type_produit3", "type_produit4", "type_produit5", "type_produit6"]
    end
    
end
  