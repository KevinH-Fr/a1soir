json.extract! paiement_recu, :id, :typepaiement, :montant, :commande_id, :moyen, :commentaires, :created_at, :updated_at
json.url polymorphic_url([:admin, paiement_recu], format: :json)
