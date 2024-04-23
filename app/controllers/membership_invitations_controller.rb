class MembershipInvitationsController < ApplicationController
  before_action :authenticate_user!, except: :show
  before_action :load_account!, except: [:show, :accept, :decline]
  before_action :load_invitation_from_token, only: :show
  before_action :load_invitation_from_invited_user, only: [:accept, :decline]

  def create
    unauthorized! unless current_user == @account.owner

    if @account.membership_invitations.create(email: params[:membership_invitation][:email], invited_by: current_user)
      redirect_to account_members_path(@account)
    else
      render 'members/new'
    end
  end

  def accept
    @invitation.accept!(current_user)
  rescue StandardError => e
    # no op
  ensure
    redirect_to root_path
  end

  def decline
    @invitation.decline!(current_user)
  rescue StandardError => e
    # no op
  ensure
    redirect_to root_path
  end

  def cancel
    # must be the one who invited
    @invitation = MembershipInvitation.pending.find_by(invited_by: current_user, account: @account, id: params[:id])
    not_found! unless @invitation

    @invitation.cancel!
  rescue StandardError => e
    # no op
  ensure
    redirect_to account_members_path(@account)
  end

  def show
    if @invitation
      render 'devise/invitations/show', layout: 'devise'
    else
      redirect_to new_user_registration_path
    end
  end

  private

  def load_invitation_from_invited_user
    @invitation = MembershipInvitation.pending.find_by(email: current_user.email, id: params[:id])
  end

  def load_invitation_from_token
    @token = params[:invitation_token]
    return if @token.blank?

    @invitation = MembershipInvitation.pending.find_by(invited_user: nil, token: @token)
  end
end