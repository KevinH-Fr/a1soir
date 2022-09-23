class ApplicationController < ActionController::Base

    def after_sign_in_path_for(resource)
        accueil_admin_path() # rediriger apres login
    end

end
