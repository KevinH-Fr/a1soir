json.extract! produit, :id, :nom, :prixvente, :prixlocation, :description, :categorie_produit_id, :caution, :handle, :reffrs, :quantite, :fournisseur_id, :dateachat, :prixachat, :created_at, :updated_at
json.url produit_url(produit, format: :json)
