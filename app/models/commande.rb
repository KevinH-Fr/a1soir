class Commande < ApplicationRecord
  belongs_to :client
  belongs_to :profile
end
