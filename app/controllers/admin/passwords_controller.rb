class Admin::PasswordsController < Devise::PasswordsController
  layout "admin"

  prepend_view_path Rails.root.join("app/views/admin/devise")

  # Après reset réussi, Devise appelle after_sign_in_path_for (si sign_in_after_reset_password).
  # Même cible que Admin::SessionsController — pas le défaut Devise (ex. root_path).
  def after_sign_in_path_for(resource)
    admin_root_path
  end

  def new
    self.resource = resource_class.new
    render template: "admin/devise/passwords/new"
  end

  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    else
      # Équivalent à respond_with(resource) avec template admin explicite (422).
      render template: "admin/devise/passwords/new", status: :unprocessable_entity
    end
  end

  def edit
    self.resource = resource_class.new
    set_minimum_password_length
    resource.reset_password_token = params[:reset_password_token]
    render template: "admin/devise/passwords/edit"
  end
end
