class AddOptimalCommitToAnalyses < ActiveRecord::Migration[7.1]
  def change
    change_table :analyses do |t|
      t.float :optimal_hourly_commit
    end
  end
end
