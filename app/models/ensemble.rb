class Ensemble < ApplicationRecord
    belongs_to :produit

    belongs_to :type_produit1, class_name: 'TypeProduit', foreign_key: 'type_produit1_id', optional: true
    belongs_to :type_produit2, class_name: 'TypeProduit', foreign_key: 'type_produit2_id', optional: true
    belongs_to :type_produit3, class_name: 'TypeProduit', foreign_key: 'type_produit3_id', optional: true
    belongs_to :type_produit4, class_name: 'TypeProduit', foreign_key: 'type_produit4_id', optional: true
    belongs_to :type_produit5, class_name: 'TypeProduit', foreign_key: 'type_produit5_id', optional: true
    belongs_to :type_produit6, class_name: 'TypeProduit', foreign_key: 'type_produit6_id', optional: true
    
  end
  