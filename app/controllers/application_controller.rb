class ApplicationController < ActionController::Base

    def after_sign_in_path_for(resource)
        accueil_admin_path() # your path
    end

end
