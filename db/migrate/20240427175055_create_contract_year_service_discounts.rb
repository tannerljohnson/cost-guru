class CreateContractYearServiceDiscounts < ActiveRecord::Migration[7.1]
  def change
    create_table :contract_year_service_discounts, id: :uuid do |t|
      t.references :service_discount, type: :uuid
      t.references :contract_year, type: :uuid

      t.timestamps
    end
  end
end
