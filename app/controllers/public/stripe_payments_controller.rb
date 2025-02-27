module Public

  class StripePaymentsController < ApplicationController
    layout 'public' 

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
    
      # Find the product
      produit = Produit.find_by(stripe_price_id: session.list_line_items.data[0].price.id)
    
      # Create a payment record for both successful and unsuccessful payments
      payment = StripePayment.create!(
        stripe_payment_id: session.payment_intent,
        produit_id: produit&.id,
        amount: session.amount_total,
        currency: session.currency,
        status: session.payment_status,
        payment_method: session.payment_method_types.first,
        charge_id: session.payment_intent
      )
      
      # Redirect to the status page with payment info
      redirect_to status_payment_path(payment.id)
    end
    

    def purchase_error
      session = Stripe::Checkout::Session.retrieve(params[:session_id])
    
      produit = Produit.find_by(stripe_price_id: session.list_line_items.data[0].price.id)
    
      StripePayment.create!(
        stripe_payment_id: session.payment_intent,
        produit_id: produit&.id,
        amount: session.amount_total,
        currency: session.currency,
        status: session.payment_status,
        payment_method: session.payment_method_types.first,
        charge_id: session.payment_intent
      )
    
      # Redirect to the status page with payment info
      redirect_to status_payment_path(payment.id)

    end

    # Status page to display payment details
    def status
      @payment = StripePayment.find(params[:id])

      if @payment.nil?
        flash[:alert] = "Payment not found."
        redirect_to root_path
      end
    end

    

  end

end