json.extract! client, :id, :prenom, :nom, :commentaires, :propart, :intitule, :tel, :tel2, :mail, :mail2, :adresse, :cp, :ville, :pays, :contact, :created_at, :updated_at
json.url client_url(client, format: :json)
