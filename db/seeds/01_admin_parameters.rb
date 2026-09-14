# frozen_string_literal: true

Seeds::Helpers.log("01", "Paramètres admin")

AdminParameter.find_or_create_by!(id: 1) do |row|
  row.tx_tva = 20
  row.coef_prix_achat_vente = 2.5
  row.coef_longue_duree = 1
  row.duree_rdv = 60
end
