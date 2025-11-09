class AddDisponibilitesToDemandeCabineEssayages < ActiveRecord::Migration[7.1]
  def change
    add_column :demande_cabine_essayages, :disponibilites, :text
  end
end
