class AccountsController < ApplicationController
    before_action :authenticate_user!
    
    def index
        @accounts = current_user.accounts
    end

    def new
        @account = Account.new
    end

    def create
        @account = Account.new(
            name: params[:account][:name], 
            iam_access_key_id: params[:account][:iam_access_key_id], 
            iam_secret_access_key: params[:account][:iam_secret_access_key]
            )
        @account.user = current_user
        if @account.save
          redirect_to account_analyses_path(@account)
        else
          render :new, status: :unprocessable_entity
        end
    end

    def show
        @account = Account.find(params[:id])
        # redirect_to account_analyses_path(@account)
    end
end
