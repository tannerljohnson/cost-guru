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

    def show
        @account = current_user.accounts.find { |account| account.id == params[:id] }
        raise "Account not found" unless @account

        @cost_summary = CostExplorer.get_cost_summary(account: @account)
    end

    private

    def account_params
        params.require(:account).permit(:name, :iam_access_key_id, :iam_secret_access_key)
    end
end
