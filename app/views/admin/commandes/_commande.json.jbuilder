json.extract! commande, :id, :nom, :montant, :description, :client_id, :debutloc, :finloc, :dateevent, :statutarticles, :typeevent, :profile_id, :commentaires, :commentaires_doc, :location, :devis, :created_at, :updated_at
json.url commande_url(commande, format: :json)
