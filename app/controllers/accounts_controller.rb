class AccountsController < ApplicationController
  before_action :authenticate_user!

  def index
    @accounts = current_user.accounts
  end

  def new
    @account = current_user.accounts.new
  end

  def create
    @account = current_user.accounts.new(account_params)
    if @account.save
      redirect_to account_analyses_path(@account)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @account = current_user.accounts.find { |account| account.id == params[:id] }
    raise "Account not found" unless @account
  end

  def update
    @account = current_user.accounts.find { |account| account.id == params[:id] }

    if @account.update(account_params)
      redirect_to account_analyses_path(@account)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    @account = current_user.accounts.find { |account| account.id == params[:id] }
    raise "Account not found" unless @account

    six_months_ago = (Time.now.utc - 6.months).beginning_of_month
    start_date = six_months_ago
    end_date = Time.now.utc
    base_request_params = {
      account: @account,
      start_date: start_date,
      end_date: end_date,
      granularity: Constants::DAILY
    }

    # TODO: figure out how to do more async
    @cost_summary = CostSummarizer.summarize(account: @account)
    @csp_coverage = CostExplorerClient.get_savings_plans_coverage(**base_request_params)
    @csp_utilization = CostExplorerClient.get_savings_plans_utilization(**base_request_params)
    @on_demand_usage = CostExplorerClient.get_cost_and_usage(**base_request_params, filter: Constants::CSP_ELIGIBLE_COST_AND_USAGE_FILTER)
    @csp_usage = CostExplorerClient.get_cost_and_usage(**base_request_params, filter: Constants::CSP_ONLY_USAGE_FILTER)
    @historical_usage_core = CostExplorerClient.get_cost_and_usage(**base_request_params, filter: Constants::EXCLUDE_IGNORED_SERVICES_FILTER, group_by: Constants::SERVICE, granularity: Constants::MONTHLY)
    @historical_usage_non_core = CostExplorerClient.get_cost_and_usage(**base_request_params, filter: Constants::IGNORED_SERVICES_ONLY_FILTER, group_by: Constants::SERVICE, granularity: Constants::MONTHLY)
  end

  private

  def account_params
    params.require(:account).permit(:name, :iam_access_key_id, :iam_secret_access_key, :role_arn)
  end
end
