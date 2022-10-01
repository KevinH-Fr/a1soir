class Client < ApplicationRecord
    has_many :commandes

    validates :nom, presence: true
    validates :mail, presence: true

    def full_name
        "#{nom} #{mail} "
    end
end
