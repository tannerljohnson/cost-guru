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

        @cost_summary = CostExplorer.get_cost_summary(account: @account)
        @csp_data = CostExplorer.get_savings_plans_coverage_and_utilization(account: @account, start_date: Time.now.utc.beginning_of_month, end_date: Time.now.utc)
        @historical_usage_core = CostExplorer.get_cost_and_usage(account: @account, start_date: Time.now.utc - 12.months, end_date: Time.now.utc, filter: Constants::EXCLUDE_IGNORED_SERVICES_FILTER, group_by: "SERVICE", granularity: "MONTHLY")
        @historical_usage_non_core = CostExplorer.get_cost_and_usage(account: @account, start_date: Time.now.utc - 12.months, end_date: Time.now.utc, filter: Constants::IGNORED_SERVICES_ONLY_FILTER, group_by: "SERVICE", granularity: "MONTHLY")
    end

    private

    def account_params
        params.require(:account).permit(:name, :iam_access_key_id, :iam_secret_access_key, :role_arn)
    end
end
