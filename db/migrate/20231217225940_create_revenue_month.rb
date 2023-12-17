class CreateRevenueMonth < ActiveRecord::Migration[7.1]
  def change
    create_table :revenue_months, id: :uuid do |t|
      t.datetime :start_date, null: false
      t.float :revenue, null: false, default: 0.0
      t.references :account, type: :uuid, null: false

      t.timestamps
    end

    add_index :revenue_months, [:account_id, :start_date], unique: true
  end
end
