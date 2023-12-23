class CreateCostAndUsage < ActiveRecord::Migration[7.1]
  def change
    create_table :cost_and_usages, id: :uuid do |t|
      t.datetime :start, null: false
      t.references :analysis, type: :uuid, null: false
      t.string :filter, null: false
      t.float :total, null: false, default: 0.0
      t.timestamps
    end
  end
end
