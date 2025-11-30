class AddDemandeRdvToMeetings < ActiveRecord::Migration[7.1]
  def change
    # Vérifier si la colonne existe déjà avant de l'ajouter
    # (utile si la colonne a été ajoutée manuellement ou par une migration précédente)
    unless column_exists?(:meetings, :demande_rdv_id)
      add_reference :meetings, :demande_rdv, null: true, foreign_key: true
    end
  end
end

