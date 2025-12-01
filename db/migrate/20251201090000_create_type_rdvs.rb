class CreateTypeRdvs < ActiveRecord::Migration[7.1]
  def change
    create_table :type_rdvs do |t|
      # "code" sera la valeur stockée dans demande_rdvs.type_rdv
      # ex: "découverte", "essayage", "retouche"
      t.string  :code,               null: false

      # Durée de base du type de RDV (en minutes)
      t.integer :duree_base_minutes, null: false, default: 60

      t.timestamps
    end

    add_index :type_rdvs, :code, unique: true
  end
end


