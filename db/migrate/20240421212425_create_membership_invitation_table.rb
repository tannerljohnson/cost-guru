class CreateMembershipInvitationTable < ActiveRecord::Migration[7.1]
  def up
    create_table :membership_invitations, id: :uuid do |t|
      t.string :invited_by, type: :uuid, null: false
      t.references :account, type: :uuid, null: false
      t.string :email, type: :email, null: false
      t.string :status, null: false
      t.string :token, null: false

      t.timestamps
    end

    add_index :membership_invitations, :account_id unless index_exists?(:membership_invitations, :account_id)
  end

  def down
    drop_table :membership_invitations
    remove_index :membership_invitations, column: :account_id if index_exists?(:membership_invitations, :account_id)
  end
end
