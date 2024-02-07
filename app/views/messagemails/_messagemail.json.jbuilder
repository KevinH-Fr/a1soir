json.extract! messagemail, :id, :titre, :body, :commentaires, :commande_id, :client_id, :created_at, :updated_at
json.url messagemail_url(messagemail, format: :json)
