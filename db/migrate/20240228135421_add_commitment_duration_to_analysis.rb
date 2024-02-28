class AddCommitmentDurationToAnalysis < ActiveRecord::Migration[7.1]
  change_table :analyses do |t|
    t.integer :commitment_years, null: false, default: 3
  end
end
