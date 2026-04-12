class Profile < ApplicationRecord
    
    ESHOP_LAST_NAME = "eshop"

    has_one_attached :profile_pic
    has_many :commandes

    # Profil vendeur pour les commandes créées depuis Stripe (peu de lignes en base : filtre Ruby, pas de LOWER SQL).
    def self.for_eshop_commandes
        row = pluck(:id, :nom).find { |_id, nom| nom.to_s.casecmp?(ESHOP_LAST_NAME) }
        return find(row.first) if row

        create!(prenom: "E-shop", nom: ESHOP_LAST_NAME)
    end

    def full_name
        prenom + " " + nom
    end

    def default_image
        if profile_pic.attached?
            profile_pic
        else
          '/images/no_photo.png'
        end
    end

    def self.ransackable_attributes(auth_object = nil)
        ["created_at", "id", "id_value", "nom", "prenom", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
        ["commandes", "profile_pic_attachment", "profile_pic_blob"]
    end

end
