class RefactorDemandeCabineEssayage < ActiveRecord::Migration[7.1]
  def change
    # Ajouter la référence vers demande_rdv
    add_reference :demande_cabine_essayages, :demande_rdv, null: true, foreign_key: true
    
    # Supprimer les champs qui seront dans demande_rdv
    remove_column :demande_cabine_essayages, :prenom, :string
    remove_column :demande_cabine_essayages, :nom, :string
    remove_column :demande_cabine_essayages, :mail, :string
    remove_column :demande_cabine_essayages, :telephone, :string
    remove_column :demande_cabine_essayages, :evenement, :string
    remove_column :demande_cabine_essayages, :date_evenement, :date
    remove_column :demande_cabine_essayages, :statut, :string
    remove_column :demande_cabine_essayages, :commentaires, :text
    remove_column :demande_cabine_essayages, :disponibilites, :text
  end
end
