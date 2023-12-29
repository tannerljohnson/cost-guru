class ApplicationController < ActionController::Base
  protected

  def not_found!
    raise ActionController::RoutingError, 'Not Found'
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end

  def after_sign_out_path_for(_)
    new_user_session_path
  end

  private

  def load_account!
    @account = current_user.accounts.find { |account| account.id == params[:account_id] }
    raise "Account not found" unless @account
  end
end
