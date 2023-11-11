class AssociateAccountsWithUser < ActiveRecord::Migration[7.1]
  def change
    change_table :accounts do |t|
      t.references :user, type: :uuid
    end
  end
end
