class DropEnsembles < ActiveRecord::Migration[7.1]
  def change
    drop_table :ensembles
  end
end
