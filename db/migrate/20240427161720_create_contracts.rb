class CreateContracts < ActiveRecord::Migration[7.1]
  def change
    create_table :contracts, id: :uuid do |t|
      t.datetime :term_start, null: false
      t.datetime :term_end, null: false
      t.decimal :cross_service_discount, null: false
      t.decimal :upfront_payment_discount, null: false
      t.references :account, type: :uuid

      t.timestamps
    end
  end
end
