# frozen_string_literal: true

class Admin::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  layout 'admin'  

  # GET /resource/sign_in
  def new
    self.resource = resource_class.new   # Initializes the resource (User)
    @resource_name = resource_name       # Ensures resource_name is set
    
    render template: "admin/devise/sessions/new" # Specifies the custom template

  end

  # POST /resource/sign_in
  def create
    super
  end

  # DELETE /resource/sign_out
  def destroy
    super
  end

  def after_sign_in_path_for(resource)
    admin_root_path  # Redirect to the admin root path
  end
  
  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
