# Hub « Dimensions » : invitations mensurations et fiches reçues. :id = invitation.
class Admin::MensurationsController < Admin::ApplicationController
  before_action :set_invitation, only: [:resend, :destroy, :photo]

  def index
    @q = MensurationInvitation.ransack(params[:q])
    scope = @q.result.includes(:client, :mensuration).order(created_at: :desc)
    @count_invitations = scope.count
    @invitations = scope
  end

  def create
    @invitation = MensurationInvitation.new(invitation_params)
    if @invitation.save
      MensurationMailer.invitation(@invitation).deliver_later
      redirect_to admin_mensurations_path, notice: "Invitation envoyée à #{@invitation.email}."
    else
      redirect_to admin_mensurations_path, alert: @invitation.errors.full_messages.to_sentence
    end
  end

  # Nouveau lien + nouvelle échéance (l'ancien token est invalidé), puis renvoi du mail.
  def resend
    @invitation.reissue!
    MensurationMailer.invitation(@invitation).deliver_later
    redirect_to admin_mensurations_path, notice: "Invitation renvoyée à #{@invitation.email}."
  end

  # Supprime invitation + fiche + photo (purge ActiveStorage) — jamais le client.
  def destroy
    @invitation.destroy
    redirect_back fallback_location: admin_mensurations_path, notice: "Fiche mensurations supprimée."
  end

  # Proxy admin : la photo client n'est jamais exposée en URL Cloudinary publique.
  # Redirige vers une URL signée à expiration courte — un nouveau lien à chaque affichage.
  def photo
    blob = @invitation.mensuration&.photo_pied&.blob
    raise ActiveRecord::RecordNotFound unless blob

    url = if blob.service_name == "cloudinary"
            Cloudinary::Utils.private_download_url(
              blob.key,
              blob.filename.extension_without_delimiter.presence || "jpg",
              resource_type: "image",
              type: "authenticated",
              expires_at: 10.minutes.from_now.to_i
            )
          else
            blob.url(disposition: :inline)
          end
    redirect_to url, allow_other_host: true
  end

  private

  def set_invitation
    @invitation = MensurationInvitation.find(params[:id])
  end

  def invitation_params
    params.require(:mensuration_invitation).permit(:email, :prenom, :nom, :template, :locale, :message_perso)
  end
end
