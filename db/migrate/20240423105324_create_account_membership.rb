class CreateAccountMembership < ActiveRecord::Migration[7.1]
  def change
    create_table :account_memberships, id: :uuid do |t|
      t.references :membership_invitation, type: :uuid, null: false
      t.references :account, type: :uuid, null: false
      t.references :user, type: :uuid, null: false

      t.timestamps
    end
  end
end
