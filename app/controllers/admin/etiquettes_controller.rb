class Admin::EtiquettesController < Admin::ApplicationController
  include PdfRenderable

  # before_action :authenticate_vendeur_or_admin!

  def index
    session[:selection_etiquettes] ||= []

    search_params = params.permit(
      :format, :page,
      q: [:nom_or_reffrs_or_handle_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_or_fournisseur_nom_cont]
    )

    produits = Produit.all

    if params[:q].present? &&
       params[:q][:nom_or_reffrs_or_handle_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_or_fournisseur_nom_cont].present?

      keywords = params[:q][:nom_or_reffrs_or_handle_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_or_fournisseur_nom_cont]
                 .to_s.strip.split

      groupings = keywords.map do |word|
        {
          nom_or_reffrs_or_handle_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_or_fournisseur_nom_cont: word
        }
      end

      @q = produits.ransack(combinator: "and", groupings: groupings)
    else
      @q = produits.ransack(params[:q])
    end

    produits = @q.result(distinct: true).order(updated_at: :desc)

    @pagy, produits_page = pagy(produits, items: 6)

    datedebut = Time.current
    datefin   = Time.current

    produits_ids = produits_page.select do |produit|
      produit.statut_disponibilite(datedebut, datefin)[:disponibles] > 0
    end.map(&:id)

    @produits = Produit.where(id: produits_ids).order(updated_at: :desc)

    @selection_produits = []
  end

  def reset_selection
    session.delete(:selection_etiquettes)
    admin_push_domain_toast!(flash, :etiquette, :selection_supprimee)
    redirect_to admin_etiquettes_path
  end

  def update_selection
    new_product = params[:new_product].to_i

    session[:selection_etiquettes] ||= []
    session[:selection_etiquettes] << new_product

    redirect_to admin_etiquettes_path
  end

  def generate_pdf
    load_etiquette_selection!
    respond_to do |format|
      format.pdf do
        send_pdf(
          template: "admin/etiquettes/edition",
          layout: "pdf_etiquettes",
          filename: "etiquette_#{Time.current.strftime('%Y%m%d_%H%M%S')}.pdf",
          pdf_options: {
            format: :A4,
            margin_top: 0,
            margin_bottom: 0,
            margin_left: 0,
            margin_right: 0
          }
        )
      end
    end
  end

  private

  def load_etiquette_selection!
    ids = session[:selection_etiquettes] || []
    produits_by_id = Produit.where(id: ids).includes(:taille, :couleur, :image1_attachment, :qr_code_attachment).index_by(&:id)
    @produits = ids.map { |id| produits_by_id[id] }.compact
  end
end
