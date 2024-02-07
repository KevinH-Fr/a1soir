json.extract! sousarticle, :id, :article_id, :produit_id, :nature, :description, :prix, :caution, :commentaires, :created_at, :updated_at
json.url sousarticle_url(sousarticle, format: :json)
