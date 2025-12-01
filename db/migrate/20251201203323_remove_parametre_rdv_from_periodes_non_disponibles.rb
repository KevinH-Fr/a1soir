class RemoveParametreRdvFromPeriodesNonDisponibles < ActiveRecord::Migration[7.1]
  def change
    remove_reference :periodes_non_disponibles, :parametre_rdv, null: false, foreign_key: true
  end
end
