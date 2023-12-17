class AddChartDataToAnalysis < ActiveRecord::Migration[7.1]
  change_table :analyses do |t|
    t.jsonb :chart_data, default: {}, null: false
  end
end
