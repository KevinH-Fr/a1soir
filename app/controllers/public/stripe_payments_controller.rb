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

      total_grams  = @cart.sum { |p| p.poids.to_i }
      fee_cents    = ShippingCostService.fee_cents_for(total_grams)
      shipping_rate = Stripe::ShippingRate.create(
        display_name: I18n.t("public.stripe_payments.shipping_label"),
        type: "fixed_amount",
        fixed_amount: { amount: fee_cents, currency: "eur" }
      )

      stripe_session = Stripe::Checkout::Session.create(
        payment_method_types: ["card"],
        line_items: @cart.map { |item| item.to_builder.attributes! },
        mode: "payment",
        shipping_options: [{ shipping_rate: shipping_rate.id }],
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
          flash.now[:alert] = t("public.stripe_payments.flash.product_not_available")
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.append(:flash, partial: "public/shared/flash"),
              turbo_stream.replace("cart_badge", partial: "public/shared/cart_nav_link"),
              shop_cart_floating_footer_stream
            ]
          end
          format.html { redirect_to produit_path(slug: @produit.nom.parameterize, id: @produit.id), alert: flash.now[:alert] }
        end
        return
      end

      respond_to do |format|
        if session[:cart].include?(id)
          flash.now[:notice] = t("public.stripe_payments.flash.already_in_cart")
        else
          session[:cart] << id
          flash.now[:success] = t("public.stripe_payments.flash.added_to_cart", name: @produit.nom)
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
            turbo_stream.replace("cart_badge", partial: "public/shared/cart_nav_link"),
            shop_cart_floating_footer_stream
          ]
        end
        format.html { redirect_to produit_path(slug: @produit.nom.parameterize, id: @produit.id) }
      end
    end

    def remove_from_cart
      id = params[:id].to_i
      @produit = Produit.find(id)
      session[:cart].delete(id)
      flash.now[:info] = t("public.stripe_payments.flash.removed_from_cart", name: @produit.nom)

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
            turbo_stream.replace("cart_badge", partial: "public/shared/cart_nav_link"),
            shop_cart_floating_footer_stream
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
        redirect_to cart_path, alert: t("public.stripe_payments.flash.invalid_session")
        return
      end

      stripe_session = StripeCheckoutFulfillmentService.retrieve_session!(params[:session_id])

      unless stripe_session.payment_status == "paid"
        redirect_to cart_path, alert: t("public.stripe_payments.flash.payment_not_finalized")
        return
      end

      result = StripeCheckoutFulfillmentService.new(stripe_session).fulfill!
      payment = result.payment

      if payment.nil?
        redirect_to cart_path, alert: t("public.stripe_payments.flash.payment_record_error")
        return
      end

      session[:cart] = [] if stripe_session.payment_status == "paid"
      session[:accessible_payment_ids] = Array(session[:accessible_payment_ids]) | [payment.id]
      redirect_to status_payment_path(payment.id),
                  notice: t("public.stripe_payments.flash.payment_success")
    rescue Stripe::InvalidRequestError, ArgumentError => e
      Rails.logger.warn("purchase_success: #{e.class} #{e.message}")
      redirect_to cart_path, alert: t("public.stripe_payments.flash.payment_confirmation_error")
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      Rails.logger.error("purchase_success fulfillment: #{e.class} #{e.message}")
      redirect_to cart_path, alert: t("public.stripe_payments.flash.payment_fulfillment_error")
    end

    def purchase_error
      redirect_to cart_path, alert: t("public.stripe_payments.flash.payment_cancelled")
    end

    def status
      accessible_ids = Array(session[:accessible_payment_ids]).map(&:to_i)
      unless accessible_ids.include?(params[:id].to_i)
        flash[:alert] = t("public.stripe_payments.flash.unauthorized")
        redirect_to root_path and return
      end

      @payment = StripePayment.includes(:commande).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = t("public.stripe_payments.flash.not_found")
      redirect_to root_path
    end

    private

    def check_online_sales
      return if OnlineSales.available?

      redirect_to root_path, alert: t("public.stripe_payments.flash.online_sales_unavailable")
    end

    def ensure_cart_eligible_for_checkout!
      if @cart.blank?
        redirect_to cart_path, alert: t("public.stripe_payments.flash.cart_empty")
        return false
      end
      unless @cart.all? { |p| p.eshop? && p.stripe_price_id.present? && p.today_availability? }
        redirect_to cart_path, alert: t("public.stripe_payments.flash.cart_items_unavailable")
        return false
      end
      true
    end

    # Même idée que CabineCartResponder#cabine_cart_floating_button_stream, mais local à ce contrôleur.
    def shop_cart_floating_footer_stream
      if show_shop_cart_floating_footer?
        turbo_stream.replace(
          "floating_shop_checkout_btn",
          partial: "public/pages/floating_shop_checkout_button"
        )
      else
        turbo_stream.replace(
          "floating_shop_checkout_btn",
          view_context.tag.div(nil, id: "floating_shop_checkout_btn")
        )
      end
    end
  end
end
