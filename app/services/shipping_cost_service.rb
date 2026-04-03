# frozen_string_literal: true

# Source unique de vérité pour les tarifs d'expédition Colissimo contre signature.
# Les mêmes données sont utilisées pour le calcul au checkout ET pour afficher
# le tableau des tarifs dans les CGV (public/pages/_shipping_tiers_table.html.erb).
class ShippingCostService
  # [poids_max_grammes, tarif_centimes]
  # Chaque ligne couvre la tranche (borne_précédente + 1)g → poids_max_grammes.
  SHIPPING_TIERS = [
    [250,   700],   # 0–250g       → 7 €
    [500,   800],   # 251–500g     → 8 €
    [750,   900],   # 501–750g     → 9 €
    [1000,  900],   # 751–1000g    → 9 €
    [2000, 1000],   # 1001–2000g   → 10 €
    [3000, 1100],   # 2001–3000g   → 11 €
    [4000, 1200],   # 3001–4000g   → 12 €
    [5000, 1300],   # 4001–5000g   → 13 €
    [6000, 1300],   # 5001–6000g   → 13 €
    [7000, 1400],   # 6001–7000g   → 14 €
    [8000, 1500],   # 7001–8000g   → 15 €
    [9000, 1600],   # 8001–9000g   → 16 €
    [10000, 1700],  # 9001–10000g  → 17 €
    [11000, 1800],  # 10001–11000g → 18 €
    [12000, 1900],  # 11001–12000g → 19 €
    [13000, 1900],  # 12001–13000g → 19 €
    [14000, 2000],  # 13001–14000g → 20 €
    [15000, 2100],  # 14001–15000g → 21 €
  ].freeze

  # Retourne le tarif en centimes pour un poids total donné (en grammes).
  # Si le poids dépasse la dernière tranche, applique le tarif maximum.
  def self.fee_cents_for(total_grams)
    tier = SHIPPING_TIERS.find { |max_g, _| total_grams <= max_g }
    (tier || SHIPPING_TIERS.last)[1]
  end
end
