class ChangeDefaultGranularityOnAnalysis < ActiveRecord::Migration[7.1]
  def change
    change_column :analyses, :granularity, :string, default: 'hourly', null: false
  end
end
