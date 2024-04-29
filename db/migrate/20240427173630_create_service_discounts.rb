class CreateServiceDiscounts < ActiveRecord::Migration[7.1]
  def change
    create_table :service_discounts, id: :uuid do |t|
      t.string :service, null: false
      t.jsonb :regions, null: false, default: []
      t.string :usage_type, null: false
      t.decimal :price, null: false
      t.string :price_unit, null: false
      t.references :contract, type: :uuid

      t.timestamps
    end
  end
end
