# == Schema Information
#
# Table name: membership_invitations
#
#  id              :uuid             not null, primary key
#  invited_by      :string           not null
#  account_id      :uuid             not null
#  email           :string           not null
#  status          :string           not null
#  token           :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  invited_user_id :uuid
#
class MembershipInvitation < ApplicationRecord
  belongs_to :account
  belongs_to :invited_by, class_name: 'User', foreign_key: 'invited_by', inverse_of: false
  belongs_to :invited_user, class_name: 'User', foreign_key: 'invited_user_id', inverse_of: false, optional: true
  has_one :account_membership

  after_initialize :set_token
  after_initialize :set_status

  after_create :send_invitation_email

  scope :pending, -> { where(status: 'pending') }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def accept!(user)
    ensure_pending!
    ActiveRecord::Base.transaction do
      # accept this invitation
      self.status = 'accepted'
      self.invited_user = user
      self.save!
      # create the membership
      membership = AccountMembership.new(user: user, membership_invitation: self, account: self.account)
      membership.save!
    end
  end

  def cancel!
    ensure_pending!
    self.status = 'cancelled'
    self.save!
  end

  def decline!(user)
    ensure_pending!
    self.status = 'declined'
    self.invited_user = user
    self.save!
  end

  private

  def ensure_pending!
    raise "Invitation status is not pending" unless self.status == 'pending'
  end

  def set_token
    self.token ||= SecureRandom.uuid
  end

  def set_status
    self.status ||= 'pending'
  end

  def send_invitation_email
    InvitationMailer.new_user(self).deliver_now
  end
end
