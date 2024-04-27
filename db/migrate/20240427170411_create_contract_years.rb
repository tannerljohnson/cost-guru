class CreateContractYears < ActiveRecord::Migration[7.1]
  def change
    create_table :contract_years, id: :uuid do |t|
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false
      t.decimal :spend_commitment, null: false
      t.references :contract, type: :uuid

      t.timestamps
    end
  end
end
