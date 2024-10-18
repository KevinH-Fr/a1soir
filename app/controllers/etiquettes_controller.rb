class EtiquettesController < ApplicationController
    # before_action :authenticate_vendeur_or_admin!
  
    def index
      @produits = Produit.all 
    end
  
    def edition
      # Store selected product IDs in the session
      session[:prod1] = params[:prod1]
      session[:prod2] = params[:prod2]
      session[:prod3] = params[:prod3]
      session[:prod4] = params[:prod4]
  
      # Redirect to the generate_pdf action to create the PDF
      redirect_to generate_pdf_etiquettes_path
    end
  
    def generate_pdf
      # Retrieve product IDs from the session
      @prod1 = Produit.find(session.delete(:prod1)) if session[:prod1].present?
      @prod2 = Produit.find(session.delete(:prod2)) if session[:prod2].present?
      @prod3 = Produit.find(session.delete(:prod3)) if session[:prod3].present?
      @prod4 = Produit.find(session.delete(:prod4)) if session[:prod4].present?
  
      @produits = [@prod1, @prod2, @prod3, @prod4]
      respond_to do |format|
        format.pdf do
            render pdf: "etiquette_#{Time.now.strftime('%Y%m%d_%H%M%S')}", # File name for the PDF
            
            :template => "etiquettes/edition",            
            formats: [:html],
            layout: 'pdf',

            disposition: "inline" # Use "inline" to open in the browser
        end
      end
    end 
  end
  