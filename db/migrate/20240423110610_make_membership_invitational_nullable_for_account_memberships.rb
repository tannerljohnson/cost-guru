class MakeMembershipInvitationalNullableForAccountMemberships < ActiveRecord::Migration[7.1]
  def change
    change_column_null :account_memberships, :membership_invitation_id, true
  end
end
