class Ensemble < ApplicationRecord
    belongs_to :produit
    belongs_to :type_produit1, class_name: 'TypeProduit', foreign_key: 'type_produit1_id'
    belongs_to :type_produit2, class_name: 'TypeProduit', foreign_key: 'type_produit2_id'
  end
  