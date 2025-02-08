# frozen_string_literal: true

class Public::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  layout 'public'  

  # GET /resource/sign_in
  def new
    self.resource = resource_class.new   # Initializes the resource (User)
    @resource_name = resource_name       # Ensures resource_name is set
    
    render template: "public/devise/sessions/new" # Specifies the custom template

  end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
