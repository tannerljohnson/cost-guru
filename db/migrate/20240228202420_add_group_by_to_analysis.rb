class AddGroupByToAnalysis < ActiveRecord::Migration[7.1]
  def change
    add_column :analyses, :group_by, :jsonb, default: nil
  end
end
