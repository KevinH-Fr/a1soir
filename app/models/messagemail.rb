class Messagemail < ApplicationRecord
  belongs_to :commande
  belongs_to :client
end
