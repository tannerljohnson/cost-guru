class AnalysesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_account!

  def index
    request_params = {
      account: @account,
      start_date: (Time.now.utc - 6.months).beginning_of_month,
      end_date: Time.now.utc,
      granularity: "DAILY"
    }
    @on_demand_usage = CostExplorer.get_cost_and_usage(**request_params, filter: Constants::CSP_ELIGIBLE_COST_AND_USAGE_FILTER)
    @csp_usage = CostExplorer.get_cost_and_usage(**request_params, filter: Constants::CSP_ONLY_USAGE_FILTER)
    @on_demand_usage_hourly = CostExplorer.get_cost_and_usage(**request_params, start_date: (Time.now.utc - 14.days).beginning_of_day, granularity: "HOURLY", filter: Constants::CSP_ELIGIBLE_COST_AND_USAGE_FILTER)
    @analyses = @account.analyses.order(created_at: :desc)
  end

  def new
    @analysis = @account.analyses.new(
      start_date: Time.now.utc.beginning_of_month,
      end_date: Time.now.utc,
      enterprise_cross_service_discount: @account.analyses.last&.enterprise_cross_service_discount || 0
    )
  end

  def create
    @analysis = @account.analyses.new(analysis_params)

    csp_eligible_cost_and_usages = CostExplorer.get_cost_and_usage(
      account: @account,
      start_date: @analysis.start_date,
      end_date: @analysis.end_date,
      granularity: @analysis.granularity,
      filter: Constants::CSP_ELIGIBLE_COST_AND_USAGE_FILTER
    )

    csp_eligible_cost_and_usages.each do |cost_and_usage|
      cost_and_usage_params = {
        filter: "csp_eligible",
        start: cost_and_usage[:start],
        total: cost_and_usage[:total]
      }
      @analysis.cost_and_usages.build(cost_and_usage_params)
    end

    # compute optimal csp prime with binary search
    @optimize_commit_results = CostExplorer.compute_optimal_csp_prime(
      account: @account,
      analysis: @analysis,
      start_date: @analysis.start_date,
      end_date: @analysis.end_date,
      enterprise_cross_service_discount: @analysis.enterprise_cross_service_discount,
      granularity: @analysis.granularity
    )

    # save that to the analysis and redirect
    @analysis.optimal_hourly_commit = @optimize_commit_results[:value]
    @analysis.chart_data = @optimize_commit_results[:chart_data]
    if @analysis.save
      redirect_to account_analysis_path(@account, @analysis)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @analysis = @account.analyses.find { |a| a.id === params[:id] }
    @full_dataset = CostExplorer.get_full_dataset(account: @account, analysis: @analysis)

    # @full_dataset = CostExplorer.get_full_dataset(
    #   account: @account,
    #   start_date: @analysis.start_date,
    #   end_date: @analysis.end_date,
    #   enterprise_cross_service_discount: @analysis.enterprise_cross_service_discount,
    #   csp_prime: @analysis.optimal_hourly_commit,
    #   granularity: @analysis.granularity.upcase,
    # )

    last_ninety_days_cost_and_usage = CostExplorer.get_cost_and_usage(account: @account, start_date: Time.now.utc - 90.days, end_date: Time.now.utc, filter: Constants::EXCLUDE_IGNORED_SERVICES_FILTER, granularity: "DAILY")
    @last_ninety_days = GraphHelpers.format_cost_and_usage_for_chart(last_ninety_days_cost_and_usage)
  end

  def destroy
    @analysis = @account.analyses.find { |a| a.id === params[:id] }
    @analysis.destroy
    flash[:notice] = "Successfully deleted!"

    redirect_to account_analyses_path(@account)
  end

  private

  def analysis_params
    params.require(:analysis).permit(:start_date, :end_date, :enterprise_cross_service_discount, :granularity)
  end

  def load_account!
    @account = current_user.accounts.find { |account| account.id == params[:account_id] }
    raise "Account not found" unless @account
  end
end
