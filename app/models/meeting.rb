class Meeting < ApplicationRecord
  belongs_to :commande
  belongs_to :client
end
