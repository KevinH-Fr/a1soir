class Article < ApplicationRecord
  belongs_to :commande
  belongs_to :produit

  scope :commande_courante, ->  (commande_courante) { where("commande_id = ?", commande_courante)}

  after_initialize :set_defaults

  def set_defaults
    self.quantite ||= 1
  end


end
