class MembersController < ApplicationController
  before_action :authenticate_user!
  before_action :load_account!

  def index
    @members = @account.account_memberships.includes(:user)
    @invitations = @account.membership_invitations.pending
  end

  def new
    @invitation = @account.membership_invitations.new(invited_by: current_user)
  end
end