json.extract! type_produit, :id, :nom, :created_at, :updated_at
json.url type_produit_url(type_produit, format: :json)
