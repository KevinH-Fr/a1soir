json.extract! fournisseur, :id, :nom, :tel, :mail, :contact, :site, :notes, :created_at, :updated_at
json.url fournisseur_url(fournisseur, format: :json)
