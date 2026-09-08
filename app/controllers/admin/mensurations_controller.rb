# Hub « Dimensions » : fiches mensurations reçues. :id = invitation.
class Admin::MensurationsController < Admin::ApplicationController
  SEARCH_FIELDS = :email_or_nom_or_prenom_or_mensuration_nom_or_mensuration_prenom_or_client_nom_or_client_prenom_cont

  before_action :set_invitation, only: [:destroy, :photo, :mark_treated]

  def index
    search_params = params.permit(q: [SEARCH_FIELDS])
    @q = MensurationInvitation.ransack(search_params[:q])
    scope = @q.result(distinct: true).merge(MensurationInvitation.admin_received)
              .includes(:client, :mensuration).order(created_at: :desc)
    @count_invitations = scope.count
    @invitations = scope
    @share_url = MensurationInvitation.public_share_url
  end

  def mark_treated
    mensuration = @invitation.mensuration
    unless mensuration
      redirect_back fallback_location: admin_mensurations_path, alert: "Aucune fiche à traiter."
      return
    end

    mensuration.mark_admin_treated!
    redirect_back fallback_location: admin_mensurations_path, notice: "Fiche marquée comme traitée."
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

    body = photo_bytes(blob)
    send_data body,
              type: image_content_type(body, blob.content_type),
              disposition: :inline,
              filename: blob.filename.to_s
  end

  private

  def set_invitation
    @invitation = MensurationInvitation.find(params[:id])
  end

  # Cloudinary peut servir un autre format que l'extension du fichier (ex. PNG vs .jpg),
  # et blob.download vérifie le checksum (IntegrityError). On lit via le service d'abord.
  def photo_bytes(blob)
    body = download_from_service(blob)
    return body if image_bytes?(body)
    return blob.download unless cloudinary_blob?(blob)

    cloudinary_photo_bytes(blob) || raise(ActiveRecord::RecordNotFound)
  end

  def download_from_service(blob)
    blob.service.download(blob.key)
  rescue StandardError
    nil
  end

  def cloudinary_blob?(blob)
    blob.service_name == "cloudinary"
  end

  def cloudinary_photo_bytes(blob)
    ext = blob.filename.extension_without_delimiter.presence
    formats = [nil, ext, "png", "jpg", "webp"].uniq
    %w[upload authenticated].each do |delivery_type|
      formats.each do |format|
        url = Cloudinary::Utils.cloudinary_url(
          blob.key.to_s,
          resource_type: :image,
          type: delivery_type,
          sign_url: true,
          secure: true,
          **{ format: format }.compact
        )
        body = download_cloudinary_url(url)
        return body if image_bytes?(body)
      end
    end

    return unless ext

    download_url = Cloudinary::Utils.private_download_url(
      blob.key.to_s,
      ext,
      resource_type: "image",
      type: "authenticated",
      expires_at: 10.minutes.from_now.to_i
    )
    body = download_cloudinary_url(download_url)
    body if image_bytes?(body)
  end

  def download_cloudinary_url(url)
    Cloudinary::Downloader.download(url)
  rescue StandardError
    nil
  end

  def image_bytes?(body)
    return false if body.blank? || body.bytesize < 12

    head = body.b[0, 12]
    head.start_with?("\xFF\xD8".b, "\x89PNG".b, "GIF8".b, "RIFF".b)
  end

  def image_content_type(body, fallback)
    head = body.to_s.b[0, 12]
    return "image/jpeg" if head.start_with?("\xFF\xD8".b)
    return "image/png" if head.start_with?("\x89PNG".b)
    return "image/gif" if head.start_with?("GIF8".b)
    return "image/webp" if head.start_with?("RIFF".b)

    fallback.presence || "image/jpeg"
  end
end
