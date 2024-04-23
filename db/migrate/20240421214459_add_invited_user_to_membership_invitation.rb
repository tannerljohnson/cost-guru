class AddInvitedUserToMembershipInvitation < ActiveRecord::Migration[7.1]
  def change
    add_column :membership_invitations, :invited_user_id, :uuid, default: nil
  end
end
