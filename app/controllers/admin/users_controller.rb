class Admin::UsersController < Admin::ApplicationController

  before_action :authenticate_user!
  #before_action :authenticate_vendeur_or_admin!
  
  before_action :set_user, only: [:toggle_status_user, :toggle_status_vendeur, :toggle_status_admin]

  def index
    @users = User.all
    @vendeurs = User.where(role: "vendeur")
    @admins = User.where(role: "admin")

  end

  def toggle_status_user
    @user.update(role: 'user')
    redirect_to users_url, notice: "le rôle a bien été modifié"
  end

  def toggle_status_vendeur
    @user.update(role: 'vendeur')
    redirect_to users_url, notice: "le rôle a bien été modifié"
  end

  def toggle_status_admin
    @user.update(role: 'admin')
    redirect_to users_url, notice: "le rôle a bien été modifié"
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end


 # Only allow a list of trusted parameters through.
 def user_params
    params.require(:user).permit(:email, :username, :role)
  end


end
