class Commande < ApplicationRecord
  belongs_to :client
  belongs_to :profile

  has_many :articles

  def full_name
    "ref#{id}_#{nom}"
  end

end
