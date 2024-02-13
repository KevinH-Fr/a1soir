class Commande < ApplicationRecord
  belongs_to :client
  belongs_to :profile

  has_many :articles
  has_many :paiement_recus

  def full_name
    "ref#{id}_#{nom}"
  end

end
