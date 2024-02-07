json.extract! article, :id, :quantite, :prix, :total, :produit_id, :commande_id, :locvente, :caution, :totalcaution, :longueduree, :commentaires, :created_at, :updated_at
json.url article_url(article, format: :json)
