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

  # Proxy admin : la photo n'est jamais une URL Cloudinary dans le HTML.
  # On envoie les octets en inline — une redirection vers /image/download n'est pas affichable dans <img>.
  def photo
    blob = @invitation.mensuration&.photo_pied&.blob
    raise ActiveRecord::RecordNotFound unless blob

    send_data photo_bytes(blob),
              type: blob.content_type.presence || "image/jpeg",
              disposition: :inline,
              filename: blob.filename.to_s
  end

  private

  def set_invitation
    @invitation = MensurationInvitation.find(params[:id])
  end

  def invitation_params
    params.require(:mensuration_invitation).permit(:email, :prenom, :nom, :template, :locale, :message_perso)
  end

  def photo_bytes(blob)
    return blob.download unless blob.service_name == "cloudinary"

    ext = blob.filename.extension_without_delimiter.presence || "jpg"
    %w[upload authenticated].each do |delivery_type|
      url = Cloudinary::Utils.cloudinary_url(
        blob.key.to_s,
        resource_type: :image,
        type: delivery_type,
        sign_url: true,
        secure: true,
        format: ext
      )
      body = Cloudinary::Downloader.download(url)
      return body if image_bytes?(body)
    end

    # Dernier recours : l'API download (non affichable en <img>) lue côté serveur.
    download_url = Cloudinary::Utils.private_download_url(
      blob.key.to_s,
      ext,
      resource_type: "image",
      type: "authenticated",
      expires_at: 10.minutes.from_now.to_i
    )
    body = Cloudinary::Downloader.download(download_url)
    return body if image_bytes?(body)

    raise ActiveRecord::RecordNotFound
  end

  def image_bytes?(body)
    return false if body.blank? || body.bytesize < 12

    head = body.b[0, 12]
    head.start_with?("\xFF\xD8".b, "\x89PNG".b, "GIF8".b, "RIFF".b)
  end
end
