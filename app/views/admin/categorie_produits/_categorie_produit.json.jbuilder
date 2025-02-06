json.extract! categorie_produit, :id, :nom, :texte_annonce, :label, :created_at, :updated_at
json.url categorie_produit_url(categorie_produit, format: :json)
