module CabineCartResponder
  extend ActiveSupport::Concern

  private

  def ensure_cabine_cart_session
    session[:cabine_cart] ||= []
  end

  def refresh_cabine_cart
    @cabine_cart = Produit.where(id: session[:cabine_cart])
  end

  def render_cabine_cart_turbo_stream_for(produit)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: cabine_cart_turbo_stream_payload(produit)
      end
    end
  end

  def cabine_cart_turbo_stream_payload(produit)
    [
      turbo_stream.replace(
        "produit_#{produit.id}_button",
        partial: "public/pages/cart_buttons/cabine_product_button",
        locals: { produit: produit }
      ),
      turbo_stream.replace(
        :flash,
        partial: "public/pages/flash"
      ),
      turbo_stream.replace(
        "cabine_badge",
        partial: "public/shared/cabine_nav_link"
      ),
      cabine_cart_floating_button_stream
    ]
  end

  def cabine_cart_floating_button_stream
    if session[:cabine_cart].present? && session[:cabine_cart].any?
      turbo_stream.replace(
        "floating_reservation_btn",
        partial: "public/pages/floating_reservation_button"
      )
    else
      turbo_stream.replace(
        "floating_reservation_btn",
        view_context.tag.div(nil, id: "floating_reservation_btn")
      )
    end
  end
end

