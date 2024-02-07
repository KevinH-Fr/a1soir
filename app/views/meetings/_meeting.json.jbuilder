json.extract! meeting, :id, :nom, :datedebut, :datefin, :commande_id, :client_id, :lieu, :created_at, :updated_at
json.url meeting_url(meeting, format: :json)
