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

end
