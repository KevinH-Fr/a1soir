class Admin::EtiquettesController < Admin::ApplicationController
  # before_action :authenticate_vendeur_or_admin!

  def index
    session[:selection_etiquettes] ||= []
  
    search_params = params.permit(
      :format, :page,
      q: [:nom_or_reffrs_or_handle_or_categorie_produits_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_cont]
    )
  
    @q = Produit.ransack(search_params[:q])
    produits = @q.result(distinct: true).order(updated_at: :desc)
  
    # ✅ Use pagy to paginate BEFORE filtering by availability
    @pagy, produits_page = pagy(produits, items: 6)
  
    # ✅ Filter only those with available stock (on this page only)
    datedebut = Time.current
    datefin   = Time.current
  
    produits_ids = produits_page.select do |produit|
      produit.statut_disponibilite(datedebut, datefin)[:disponibles] > 0
    end.map(&:id)
  
    @produits = Produit.where(id: produits_ids).order(updated_at: :desc)
  
    @selection_produits = []
  end
  

  def reset_selection
    # Reset the session selection
    session[:selection_etiquettes] = []
    redirect_to admin_etiquettes_path, notice: "Selection a été supprimée."
  end

  def update_selection
    # Get the existing selection_produits from params
    new_product = params[:new_product].to_i  # Access the passed value

    # Initialize or update session[:selection_etiquettes] to append the new value
    session[:selection_etiquettes] ||= []  # Ensure it's an array
    session[:selection_etiquettes] << new_product  # Add the new value to the array
  
    redirect_to admin_etiquettes_path
  end
  
  def generate_pdf
    # autoriser plusieurs fois le meme id
    ids = session[:selection_etiquettes] || []
    produits_by_id = Produit.where(id: ids).includes(:taille, :couleur, :image1_attachment, :qr_code_attachment).index_by(&:id)
    @produits = ids.map { |id| produits_by_id[id] }.compact
    #@produits = Produit.where(id: session[:selection_etiquettes]).includes([:taille], [:couleur], [:image1_attachment], [:qr_code_attachment])

    @produits_count = @produits.count { |prod| prod.present? } 
    
    respond_to do |format|
      format.pdf do
          render pdf: "etiquette_#{Time.now.strftime('%Y%m%d_%H%M%S')}", # File name for the PDF
          
          :template => "admin/etiquettes/edition",            
          formats: [:html],
          layout: 'pdf',

          disposition: "inline" # Use "inline" to open in the browser
      end
    end
  end 

end
