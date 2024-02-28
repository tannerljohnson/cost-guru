class ChangeDefaultGranularityOnAnalysisToUpcase < ActiveRecord::Migration[7.1]
  def change
    change_column :analyses, :granularity, :string, default: 'HOURLY', null: false
  end
end
