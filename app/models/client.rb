class Client < ApplicationRecord
    has_many :commandes

    def full_name
        "#{nom} #{mail} "
    end
end
