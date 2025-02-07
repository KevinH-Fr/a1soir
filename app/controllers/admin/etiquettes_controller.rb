class Admin::EtiquettesController < Admin::ApplicationController
    # before_action :authenticate_vendeur_or_admin!
  
    def index
      #@produits = Produit.all 
      session[:selection_etiquettes] = [] unless session[:selection_etiquettes]
      search_params = params.permit(:format, :page, 
        q:[:nom_or_reffrs_or_handle_or_categorie_produit_nom_or_type_produit_nom_or_couleur_nom_or_taille_nom_cont])
        
      @q = Produit.ransack(search_params[:q])
      produits = @q.result(distinct: true).order(nom: :asc)
      @pagy, @produits = pagy_countless(produits, items: 6)
  
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
  
      @produits = Produit.where(id: session[:selection_etiquettes]).includes([:taille], [:couleur], [:image1_attachment], [:qr_code_attachment])
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
  