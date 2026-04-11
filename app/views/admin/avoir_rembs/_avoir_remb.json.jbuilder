json.extract! avoir_remb, :id, :type_avoir_remb, :montant, :nature, :commande_id, :custom_date, :created_at, :updated_at
json.url polymorphic_url([:admin, avoir_remb], format: :json)
