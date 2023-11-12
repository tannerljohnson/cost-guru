class AddGranularityToAnalysis < ActiveRecord::Migration[7.1]
  def change
    change_table :analyses do |t|
      t.string :granularity, default: 'daily', null: false
    end
  end
end
