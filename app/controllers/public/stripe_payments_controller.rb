module Public
  class StripePaymentsController < ApplicationController
    before_action :check_online_sales

    layout "public"

    def create
      return unless ensure_cart_eligible_for_checkout!

      # Ne pas utiliser root_url ici : default_url_options ajoute ?locale=fr et une concaténation
      # produit une URL invalide du type /?locale=fr/purchase_success?... (Stripe ne rappelle jamais purchase_success).
      # Stripe exige le littéral {CHECKOUT_SESSION_ID} non encodé dans la chaîne envoyée à leur API.
      success_url = "#{request.base_url}#{purchase_success_path(locale: I18n.locale)}?session_id={CHECKOUT_SESSION_ID}"
      cancel_url = "#{request.base_url}#{purchase_error_path(locale: I18n.locale)}?session_id={CHECKOUT_SESSION_ID}"

      stripe_session = Stripe::Checkout::Session.create(
        payment_method_types: ["card"],
        line_items: @cart.map { |item| item.to_builder.attributes! },
        mode: "payment",
        success_url: success_url,
        cancel_url: cancel_url,
        metadata: {
          locale: I18n.locale.to_s,
          cart_product_ids: session[:cart].join(",")
        }
      )

      redirect_to stripe_session.url, allow_other_host: true
    end

    def add_to_cart
      id = params[:id].to_i
      @produit = Produit.find(id)

      unless @produit.eshop? && @produit.stripe_price_id.present?
        respond_to do |format|
          flash.now[:alert] = "Ce produit n'est pas disponible à l'achat en ligne."
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.append(:flash, partial: "public/shared/flash"),
              turbo_stream.replace("cart_badge", partial: "public/shared/cart_nav_link")
            ]
          end
          format.html { redirect_to produit_path(slug: @produit.nom.parameterize, id: @produit.id), alert: flash.now[:alert] }
        end
        return
      end

      respond_to do |format|
        if session[:cart].include?(id)
          flash.now[:notice] = "Ce produit est déjà dans votre panier"
        else
          session[:cart] << id
          flash.now[:success] = "#{@produit.nom} ajouté à votre panier"
        end

        ids = session[:cart]
        by_id = Produit.where(id: ids).index_by(&:id)
        @cart = ids.filter_map { |cid| by_id[cid] }

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "produit_#{@produit.id}_button",
              partial: "public/pages/cart_buttons/shop_product_button",
              locals: { produit: @produit }
            ),
            turbo_stream.append(:flash, partial: "public/shared/flash"),
            turbo_stream.replace("cart_badge", partial: "public/shared/cart_nav_link")
          ]
        end
        format.html { redirect_to produit_path(slug: @produit.nom.parameterize, id: @produit.id) }
      end
    end

    def remove_from_cart
      id = params[:id].to_i
      @produit = Produit.find(id)
      session[:cart].delete(id)
      flash.now[:info] = "#{@produit.nom} retiré de votre panier"

      by_id = Produit.where(id: session[:cart]).index_by(&:id)
      @cart = session[:cart].filter_map { |cid| by_id[cid] }

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "produit_#{@produit.id}_button",
              partial: "public/pages/cart_buttons/shop_product_button",
              locals: { produit: @produit }
            ),
            turbo_stream.append(:flash, partial: "public/shared/flash"),
            turbo_stream.replace("cart_badge", partial: "public/shared/cart_nav_link")
          ]
        end
        format.html { redirect_to produit_path(slug: @produit.nom.parameterize, id: @produit.id) }
      end
    end

    def remove_from_cart_go_back_to_cart
      id = params[:id].to_i
      session[:cart].delete(id)
      redirect_to cart_path
    end

    def purchase_success
      if params[:session_id].blank?
        redirect_to cart_path, alert: "Session de paiement invalide."
        return
      end

      stripe_session = StripeCheckoutFulfillmentService.retrieve_session!(params[:session_id])

      unless stripe_session.payment_status == "paid"
        redirect_to cart_path, alert: "Le paiement n'est pas finalisé."
        return
      end

      result = StripeCheckoutFulfillmentService.new(stripe_session).fulfill!
      payment = result.payment

      if payment.nil?
        redirect_to cart_path, alert: "Impossible d'enregistrer le paiement. Contactez le magasin."
        return
      end

      session[:cart] = [] if stripe_session.payment_status == "paid"
      redirect_to status_payment_path(payment.id),
                  notice: "Votre paiement a bien été enregistré. Merci pour votre achat !"
    rescue Stripe::InvalidRequestError, ArgumentError => e
      Rails.logger.warn("purchase_success: #{e.class} #{e.message}")
      redirect_to cart_path, alert: "Erreur lors de la confirmation du paiement."
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      Rails.logger.error("purchase_success fulfillment: #{e.class} #{e.message}")
      redirect_to cart_path, alert: "Erreur lors de l'enregistrement de la commande."
    end

    def purchase_error
      redirect_to cart_path, alert: "Paiement annulé ou interrompu. Votre panier est toujours disponible."
    end

    def status
      @payment = StripePayment.includes(:commande).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = "Paiement introuvable."
      redirect_to root_path
    end

    private

    def check_online_sales
      return if OnlineSales.available?

      redirect_to root_path, alert: "Online sales are currently unavailable."
    end

    def ensure_cart_eligible_for_checkout!
      if @cart.blank?
        redirect_to cart_path, alert: "Votre panier est vide."
        return false
      end
      unless @cart.all? { |p| p.eshop? && p.stripe_price_id.present? && p.today_availability? }
        redirect_to cart_path,
                    alert: "Un ou plusieurs articles ne sont plus disponibles à la vente en ligne. Vérifiez votre panier."
        return false
      end
      true
    end
  end
end
