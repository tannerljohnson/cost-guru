class AddStartDateAndEndDateToAnalysis < ActiveRecord::Migration[7.1]
  def change
    change_table :analyses do |t|
      t.datetime :start_date
      t.datetime :end_date
    end
  end
end
