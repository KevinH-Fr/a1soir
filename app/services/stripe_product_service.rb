class StripeProductService
  def initialize(produit)
    @produit = produit
    return unless ENV["ONLINE_SALES_AVAILABLE"] == "true"
  end

  def create_product_and_price
      
    return if @produit.stripe_product_id.present? && @produit.stripe_price_id.present?
  
    stripe_product = Stripe::Product.create({
      name: @produit.nom,
      description: @produit.description
    })

    stripe_price = Stripe::Price.create({
      unit_amount: (@produit.prixvente * 100).to_i,
      currency: 'eur',
      product: stripe_product.id
    })

    @produit.update_columns(stripe_product_id: stripe_product.id, stripe_price_id: stripe_price.id)
  end

  def update_product_and_price

    return unless @produit.stripe_product_id.present? && @produit.stripe_price_id.present?

    # Update product details (name and description)
    Stripe::Product.update(@produit.stripe_product_id, {
      name: @produit.nom,
      description: @produit.description
    })
  
    # Only create a new price if the price has changed
    if @produit.saved_change_to_prixvente?
      # Deactivate the old price
      Stripe::Price.update(@produit.stripe_price_id, { active: false })
  
      # Create a new price with the updated amount
      new_stripe_price = Stripe::Price.create({
        product: @produit.stripe_product_id,
        unit_amount: (@produit.prixvente * 100).to_i,
        currency: 'eur'
      })
  
      # Update the produit with the new price ID
      @produit.update_column(:stripe_price_id, new_stripe_price.id)
    end
  end
    
end
  