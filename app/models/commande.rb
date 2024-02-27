class Commande < ApplicationRecord
  belongs_to :client
  belongs_to :profile

  has_many :articles
  has_many :paiement_recus
  has_many :avoir_rembs
  has_many :meetings 
  
  def full_name
    "ref#{id}_#{nom}"
  end

  def ref_commande
    "C#{ 1000 + id }"
  end
end
