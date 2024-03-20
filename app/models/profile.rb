class Profile < ApplicationRecord
    
    has_one_attached :profile_pic

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
        ["profile_pic_attachment", "profile_pic_blob"]
    end

end
