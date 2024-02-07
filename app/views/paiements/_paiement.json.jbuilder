json.extract! paiement, :id, :typepaiement, :montant, :commande_id, :moyen, :commentaires, :created_at, :updated_at
json.url paiement_url(paiement, format: :json)
