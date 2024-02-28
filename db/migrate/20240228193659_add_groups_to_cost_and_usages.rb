class AddGroupsToCostAndUsages < ActiveRecord::Migration[7.1]
  def change
    add_column :cost_and_usages, :groups, :jsonb, default: []
  end
end
