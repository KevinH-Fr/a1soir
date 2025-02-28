module Public

  class StripePaymentsController < ApplicationController
    layout 'public' 

    def create
      # Create a Stripe Checkout Session
      session = Stripe::Checkout::Session.create(
        payment_method_types: ['card'],
        line_items: @cart.collect { |item| item.to_builder.attributes! },
        mode: 'payment',
        success_url: root_url + "purchase_success?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: root_url + "purchase_error"
      )

      # Redirect to Stripe Checkout
      redirect_to session.url, allow_other_host: true
    end

    def add_to_cart
      id = params[:id].to_i
      session[:cart] << id unless session[:cart].include?(id)
      redirect_to produit_path(id)
    end
  
    def remove_from_cart
      id = params[:id].to_i
      session[:cart].delete(id)
      redirect_to produit_path(id)
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