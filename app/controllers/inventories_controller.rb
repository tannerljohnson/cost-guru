class InventoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_account!

  def index
    @savings_plans = SavingsPlansClient.describe_savings_plans(account: @account)
  end
end