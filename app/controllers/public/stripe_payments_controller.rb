module Public

  class StripePaymentsController < ApplicationController
    layout 'public' 

      def new
      end
      
      # def create
      #   customer = Stripe::Customer.create({
      #     :email => params[:stripeEmail],
      #     :source => params[:stripeToken]
      #   })
        
      #   charge = Stripe::Charge.create({
      #     :customer => customer.id,
      #     :amount => 500,
      #     :description => 'Description of your product',
      #     :currency => 'usd'
      #   })
      
      #   rescue Stripe::CardError => e
      #     flash[:error] = e.message
      #     redirect_to new_payment_path
      # end


    def create
      # Retrieve the produit_id from the params
      produit_id = params[:produit_id]

      # Ensure that the produit_id exists
      if produit_id.nil?
        flash[:alert] = "Product ID is missing."
        redirect_to root_path
        return
      end

      # Find the product in the database (adjust according to your model)
      produit = Produit.find_by(id: produit_id)

      # Ensure that the product exists
      if produit.nil?
        flash[:alert] = "Product not found."
        redirect_to root_path
        return
      end

      # Retrieve the price_id associated with the product
      stripe_price_id = produit.stripe_price_id  # Assuming your `Produit` model has a `price_id` attribute

      # Ensure price_id exists
      if stripe_price_id.nil?
        flash[:alert] = "Price information is missing for this product."
        redirect_to root_path
        return
      end

      begin
        # Create a Stripe Checkout Session
        session = Stripe::Checkout::Session.create(
          payment_method_types: ['card'],
          line_items: [{
            price: stripe_price_id,  # Use the price_id retrieved from the product
            quantity: 1
          }],
          mode: 'payment',
          success_url: root_url + "purchase_success?session_id={CHECKOUT_SESSION_ID}",
          cancel_url: root_url + "purchase_error"
        )

        # Redirect to Stripe Checkout
        redirect_to session.url, allow_other_host: true
      rescue Stripe::StripeError => e
        flash[:error] = "Stripe error: #{e.message}"
        redirect_to root_path
      end
    end

    def purchase_success
      session = Stripe::Checkout::Session.retrieve(params[:session_id])
      if session.payment_status == 'paid'
        puts " __________ payment done successfully! _______________"
      end
    end

    def purchase_error
      puts " __________ payment error _______________"
    end

  end

end