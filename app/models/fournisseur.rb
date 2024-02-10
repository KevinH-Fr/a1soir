class Fournisseur < ApplicationRecord
    validates :nom, presence: true
end
