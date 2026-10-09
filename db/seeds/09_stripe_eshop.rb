# frozen_string_literal: true

# Crée de vrais Product / Price Stripe (mode test) pour les SKU e-shop.
# Inclus dans `bin/rails db:seed` (après 05_catalogue). Aussi :
#
#   bin/rails seeds:run[09_stripe_eshop]
#   SEED_ONLY=09_stripe_eshop bin/rails db:seed
#
# Prérequis : STRIPE_SECRET_KEY=sk_test_… dans .env, ONLINE_SALES_AVAILABLE=true pour le front.

Seeds::Helpers.log("09", "Sync e-shop → Stripe test")

secret = Stripe.api_key.to_s
if secret.blank?
  Seeds::Helpers.log("09", "Abandon : STRIPE_SECRET_KEY manquante")
  return
end

unless secret.start_with?("sk_test_")
  Seeds::Helpers.log(
    "09",
    "Abandon : clé non-test (#{secret[0, 8]}…). Utilise uniquement sk_test_… en local."
  )
  return
end

scope = Produit.where(eshop: true)
               .where("prixvente IS NOT NULL AND prixvente > 0")
               .order(:id)

if scope.none?
  Seeds::Helpers.log("09", "Aucun produit e-shop avec prixvente — lance d'abord 05_catalogue")
  return
end

ok = 0
errors = 0

scope.find_each do |produit|
  price_id = produit.stripe_price_id.to_s
  product_id = produit.stripe_product_id.to_s

  # Remplace les placeholders seed ; laisse les vrais IDs Stripe intacts.
  if price_id.start_with?("price_seed_") || product_id.start_with?("prod_seed_")
    produit.update_columns(stripe_product_id: nil, stripe_price_id: nil)
    produit.reload
  end

  begin
    if produit.stripe_price_id.present? && produit.stripe_product_id.present?
      StripeProductService.new(produit).update_product_and_price
    else
      StripeProductService.new(produit).create_product_and_price
    end
    produit.reload
    Seeds::Helpers.log(
      "09",
      "OK ##{produit.id} #{produit.nom} → #{produit.stripe_price_id}"
    )
    ok += 1
  rescue Stripe::StripeError => e
    errors += 1
    Seeds::Helpers.log(
      "09",
      "Erreur ##{produit.id} #{produit.nom} : #{e.class} — #{e.message}"
    )
  end
end

Seeds::Helpers.log("09", "Terminé : #{ok} OK, #{errors} erreur(s), #{scope.count} e-shop")
