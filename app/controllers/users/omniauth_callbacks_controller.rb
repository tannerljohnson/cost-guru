# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  protect_from_forgery prepend: true, with: :exception

  def google_oauth2
    user = User.from_google(email: auth.info.email, first_name: auth.info.first_name, last_name: auth.info.last_name)

    if user
      perform_sign_in(user)
    else
      failed_sign_in('Google', auth.info.email)
    end
  end

  def passthru
    puts "Reached passthru method"
    super
  end

  private

  def perform_sign_in(user)
    # save the original path the user went to, sign_out_all_scopes will clear it from session
    original_path = stored_location_for(user)
    sign_out_all_scopes

    store_location_for(user, original_path)
    sign_in_and_redirect user, event: :authentication
  end

  def failed_sign_in(kind, email)
    flash[:alert] = I18n.t(
      'devise.omniauth_callbacks.failure',
      kind: kind,
      reason: "no account was found for #{email}."
    )
    redirect_to new_user_session_path
  end

  def auth
    @auth ||= request.env['omniauth.auth']
  end
end
