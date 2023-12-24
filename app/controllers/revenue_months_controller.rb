class RevenueMonthsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_account!

  def index
    @revenue_months = @account.revenue_months.order(start_date: :desc)
    start_date = @revenue_months.last.start_date.beginning_of_month
    @spend_by_month = CostAndUsageFetcher.fetch(
      account: @account,
      start_date: start_date,
      end_date: Time.now.utc,
      granularity: Constants::MONTHLY,
      filter: Constants::EXCLUDE_IGNORED_SERVICES_FILTER
    )
  end

  def new
    @revenue_month = @account.revenue_months.new(
      start_date: Time.now.utc.beginning_of_month,
      revenue: 0.0
    )
  end

  def create
    @revenue_month = @account.revenue_months.new(revenue_month_params)
    if @revenue_month.save
      redirect_to account_revenue_months_path(@account)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @revenue_month = @account.revenue_months.find { |a| a.id === params[:id] }
    @revenue_month.destroy
    flash[:notice] = "Successfully deleted!"

    redirect_to account_revenue_months_path(@account)
  end

  private

  def revenue_month_params
    params.require(:revenue_month).permit(:start_date, :revenue)
  end

  def load_account!
    @account = current_user.accounts.find { |account| account.id == params[:account_id] }
    raise "Account not found" unless @account
  end
end
