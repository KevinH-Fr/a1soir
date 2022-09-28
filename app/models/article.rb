class Article < ApplicationRecord
  belongs_to :commande
  belongs_to :produit

  scope :commande_courante, ->  (commande_courante) { where("commande_id = ?", commande_courante)}
  scope :division_courant, -> (division_courant) { joins(:event).where("division_id = ?", division_courant)}

end
