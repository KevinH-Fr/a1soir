module Public
  class StripePaymentsController < ApplicationController
    before_action :check_online_sales

    layout 'public'

    def create
      # Create a Stripe Checkout Session
      session = Stripe::Checkout::Session.create(
        payment_method_types: ['card'],
        line_items: @cart.collect { |item| item.to_builder.attributes! },
        mode: 'payment',
        success_url: root_url + "purchase_success?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: root_url + "purchase_error?session_id={CHECKOUT_SESSION_ID}"
      )

      # Redirect to Stripe Checkout
      redirect_to session.url, allow_other_host: true
    end

    def add_to_cart
      id = params[:id].to_i
      @produit = Produit.find(id)

      respond_to do |format|
        if session[:cart].include?(id)
          flash.now[:notice] = "Ce produit est déjà dans votre panier"
        else
          session[:cart] << id
          flash.now[:success] = "#{@produit.nom} ajouté à votre panier"
        end

        format.turbo_stream do
          render turbo_stream: [
            # bouton du produit
            turbo_stream.replace(
              "produit_#{@produit.id}_button",
              partial: "public/pages/cart_buttons/shop_product_button",
              locals: { produit: @produit }
            ),
            # flash
            turbo_stream.append(
              :flash,
              partial: "public/pages/flash"
            ),
            # badge navbar
            turbo_stream.replace(
              "cart_badge",
              partial: "public/shared/cart_nav_link"
            )
          ]
        end
        format.html { redirect_to produit_path(id) }
      end
    end

    def remove_from_cart
      id = params[:id].to_i
      @produit = Produit.find(id)
      session[:cart].delete(id)
      flash.now[:info] = "#{@produit.nom} retiré de votre panier"

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            # bouton du produit
            turbo_stream.replace(
              "produit_#{@produit.id}_button",
              partial: "public/pages/cart_buttons/shop_product_button",
              locals: { produit: @produit }
            ),
            # flash
            turbo_stream.append(
              :flash,
              partial: "public/pages/flash"
            ),
            # badge navbar
            turbo_stream.replace(
              "cart_badge",
              partial: "public/shared/cart_nav_link"
            )
          ]
        end
        format.html { redirect_to produit_path(id) }
      end
    end

    def remove_from_cart_go_back_to_cart
      id = params[:id].to_i
      session[:cart].delete(id)
      redirect_to cart_path
    end

    def purchase_success
      stripe_session = Stripe::Checkout::Session.retrieve({
        id: params[:session_id],
        expand: ['line_items.data.price.product']
      })
    
      payment = StripePayment.create!(
        stripe_payment_id: stripe_session.payment_intent,
        amount: stripe_session.amount_total,
        currency: stripe_session.currency,
        status: stripe_session.payment_status,
        payment_method: stripe_session.payment_method_types.first,
        charge_id: stripe_session.payment_intent
      )
    
      session[:cart].each do |item|
        produit = Produit.find(item) 
        StripePaymentItem.create!(
          stripe_payment: payment,
          produit: produit
        )
      end
    
      if stripe_session.payment_status == 'paid'
        session[:cart] = []
      end
      
      redirect_to status_payment_path(payment.id)
    end
    

    def purchase_error
      # stripe_session = Stripe::Checkout::Session.retrieve({
      #   id: params[:session_id],
      #   expand: ['line_items.data.price.product']
      # })
    
      # payment = StripePayment.create!(
      #   stripe_payment_id: stripe_session.payment_intent,
      #   amount: stripe_session.amount_total,
      #   currency: stripe_session.currency,
      #   status: stripe_session.payment_status,
      #   payment_method: stripe_session.payment_method_types.first,
      #   charge_id: stripe_session.payment_intent
      # )
    
      redirect_to cart_path
    end

    def status
      @payment = StripePayment.find(params[:id])
      if @payment.nil?
        flash[:alert] = "Payment not found."
        redirect_to root_path
      end
    end

    private

    def check_online_sales
      unless ENV["ONLINE_SALES_AVAILABLE"] == "true"
        redirect_to root_path, alert: "Online sales are currently unavailable."
      end
    end
  end
end
