class AddCustomDateToAvoirRembs < ActiveRecord::Migration[7.1]
  def change
    add_column :avoir_rembs, :custom_date, :date
  end
end
