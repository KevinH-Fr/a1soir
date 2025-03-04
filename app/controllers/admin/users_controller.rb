class Admin::UsersController < Admin::ApplicationController

  before_action :authenticate_admin!
  
  before_action :set_user, only: [:toggle_status_user, :toggle_status_vendeur, :toggle_status_admin]

  def index
    @users = User.where(role: "user")
    @vendeurs = User.where(role: "vendeur")
    @admins = User.where(role: "admin")
  end

  def toggle_status_user
    @user.update(role: 'user')
    redirect_to admin_users_url, notice: "le rôle a bien été modifié"
  end

  def toggle_status_vendeur
    @user.update(role: 'vendeur')
    redirect_to admin_users_url, notice: "le rôle a bien été modifié"
  end

  def toggle_status_admin
    @user.update(role: 'admin')
    redirect_to admin_users_url, notice: "le rôle a bien été modifié"
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :username, :role)
  end

end
