# frozen_string_literal: true
class InvitationMailer < ApplicationMailer
  def new_user(invitation)
    @email = invitation.email
    @invited_by = invitation.invited_by
    @token = invitation.token
    @account = invitation.account.name

    mail(to: @email, from: @invited_by.email, subject: "You're invited Artemis")
  end
end