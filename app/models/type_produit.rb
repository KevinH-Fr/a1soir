class TypeProduit < ApplicationRecord
    has_many :ensembles

    scope :types_enfants_unique, -> { where.not(nom: 'ensemble').distinct }

end
