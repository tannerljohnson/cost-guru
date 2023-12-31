class AnomaliesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_account!

  def index
    # TODO: remove fixture and make real call
    # @cost_and_usage = Constants.generate_cost_and_usage_test_fixture
    @cost_and_usage = CostExplorerClient.get_cost_and_usage(
      account: @account,
      start_date: Time.now.utc - 3.months,
      end_date: Time.now.utc,
      granularity: Constants::DAILY,
      filter: Constants::EXCLUDE_IGNORED_SERVICES_FILTER,
      group_by: Constants::SERVICE
    )
  end
end