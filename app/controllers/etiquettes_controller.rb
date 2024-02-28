class EtiquettesController < ApplicationController
    def index
        @produits = Produit.all 
    end

    def edition
       @produit1 =  Produit.find(params[:prod1]) if params[:prod1].present?
       @produit2 =  Produit.find(params[:prod2]) if params[:prod2].present?
       @produit3 =  Produit.find(params[:prod3]) if params[:prod3].present?
       @produit4 =  Produit.find(params[:prod4]) if params[:prod4].present?

       respond_to do |format|
        format.html
        format.pdf do
            render pdf: "etiquette_#{Time.now.strftime('%Y%m%d_%H%M%S')}.pdf",
                :margin => {
                :top => 5,
                :bottom => 0
                },
                
                :template => "etiquettes/edition",            
                formats: [:html],
                layout: 'pdf'
        end
      end

    end 


end
