# == Schema Information
#
# Table name: account_memberships
#
#  id                       :uuid             not null, primary key
#  membership_invitation_id :uuid
#  account_id               :uuid             not null
#  user_id                  :uuid             not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
class AccountMembership < ApplicationRecord
  belongs_to :user
  belongs_to :account
  belongs_to :membership_invitation, optional: true
end
