class Commande < ApplicationRecord
  belongs_to :client
  belongs_to :profile

  def full_name
    "ref#{id}_#{nom}"
  end

end
