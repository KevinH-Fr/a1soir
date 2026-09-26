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

    send_data @invitation.mensuration.photo_pied_bytes,
              type: blob.content_type.presence || "image/jpeg",
              disposition: :inline,
              filename: blob.filename.to_s
  end

  private

  def set_invitation
    @invitation = MensurationInvitation.find(params[:id])
  end
end
