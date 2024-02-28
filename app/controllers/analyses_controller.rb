class AnalysesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_account!

  def index
    request_params = {
      account: @account,
      start_date: (Time.now.utc - 6.months).beginning_of_month,
      end_date: Time.now.utc,
      granularity: Constants::DAILY
    }
    # @on_demand_usage = CostAndUsageFetcher.fetch(**request_params, filter: Constants::CSP_ELIGIBLE_COST_AND_USAGE_FILTER)
    @on_demand_usage = CostExplorerClient.get_cost_and_usage(**request_params, filter: Constants::CSP_ELIGIBLE_COST_AND_USAGE_FILTER)
    # @csp_usage = CostAndUsageFetcher.fetch(**request_params, filter: Constants::CSP_ONLY_USAGE_FILTER)
    @csp_usage = CostExplorerClient.get_cost_and_usage(**request_params, filter: Constants::CSP_ONLY_USAGE_FILTER)
    # @on_demand_usage_hourly = CostAndUsageFetcher.fetch(
    @on_demand_usage_hourly = CostExplorerClient.get_cost_and_usage(
      **request_params,
      start_date: (Time.now.utc - 14.days).beginning_of_day,
      granularity: Constants::HOURLY,
      filter: Constants::CSP_ELIGIBLE_COST_AND_USAGE_FILTER
    )
    @analyses = @account.analyses.order(created_at: :desc)
  end

  def new
    @analysis = @account.analyses.new(
      start_date: Time.now.utc - 14.days,
      end_date: Time.now.utc,
      enterprise_cross_service_discount: @account.analyses.last&.enterprise_cross_service_discount || 0,
      granularity: Constants::HOURLY
    )
  end

  def create
    @analysis = @account.analyses.new(analysis_params)
    unless @analysis.save
      render :new, status: :unprocessable_entity
      return
    end

    build_cost_and_usages
    # Save so we can query for cost_and_usages in cost explorer call
    unless @analysis.save
      render :new, status: :unprocessable_entity
    end

    compute_csp_prime_and_chart_data
    if @analysis.save
      redirect_to account_analysis_path(@account, @analysis)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @analysis = @account.analyses.find { |a| a.id === params[:id] }
    unless @analysis.update(analysis_params)
      render :edit, status: :unprocessable_entity
      return
    end

    # purge all current cost_and_usages
    @analysis.cost_and_usages.destroy_all
    build_cost_and_usages
    # Save so we can query for cost_and_usages in cost explorer call
    unless @analysis.save
      render :edit, status: :unprocessable_entity
    end

    compute_csp_prime_and_chart_data
    if @analysis.save
      redirect_to account_analysis_path(@account, @analysis)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def show
    # Preload cost and usages for use in the view and avoid n+1 queries
    @analysis = Analysis.includes(:cost_and_usages).find_by(id: params[:id], account: @account)
    # No remote calls to AWS
    @full_dataset = ComputeSavingsPlansOptimizer.get_full_dataset(
      account: @account,
      analysis: @analysis,
      start_date: @analysis.start_date,
      end_date: @analysis.end_date,
      enterprise_cross_service_discount: @analysis.enterprise_cross_service_discount,
      csp_prime: @analysis.optimal_hourly_commit,
      granularity: @analysis.granularity.upcase,
      commitment_years: @analysis.commitment_years
    )
  end

  def edit
    @analysis = @account.analyses.find { |a| a.id === params[:id] }
  end

  def destroy
    @analysis = @account.analyses.find { |a| a.id === params[:id] }
    @analysis.destroy
    flash[:notice] = "Successfully deleted!"

    redirect_to account_analyses_path(@account)
  end

  private

  def analysis_params
    params.require(:analysis).permit(:start_date, :end_date, :enterprise_cross_service_discount, :granularity, :commitment_years, :group_by)
  end

  def build_cost_and_usages
    # Build and cache all the cost and usages for faster rendering
    CostExplorerClient.get_cost_and_usage(
      account: @account,
      start_date: @analysis.start_date,
      end_date: @analysis.end_date,
      granularity: @analysis.granularity,
      filter: Constants::CSP_ELIGIBLE_COST_AND_USAGE_FILTER,
      group_by: Constants::GROUP_BY_OPTIONS[@analysis.group_by]
    ).each do |cost_and_usage|
      @analysis.cost_and_usages.build(
        filter: "csp_eligible",
        start: cost_and_usage[:start],
        total: cost_and_usage[:total],
        groups: cost_and_usage[:groups]
      )
    end

    # Same thing but do it for csp_payment type
    CostExplorerClient.get_savings_plans_utilization(
      account: @account,
      start_date: @analysis.start_date,
      end_date: @analysis.end_date,
      granularity: @analysis.granularity,
      enterprise_cross_service_discount: @analysis.enterprise_cross_service_discount,
    ).each do |savings_plan_cost_and_usage|
      @analysis.cost_and_usages.build(
        filter: "csp_payment",
        start: savings_plan_cost_and_usage[:start],
        total: savings_plan_cost_and_usage[:total]
      )
    end
  end

  def compute_csp_prime_and_chart_data
    # Compute optimal csp prime with binary search
    @optimize_commit_results = ComputeSavingsPlansOptimizer.compute_optimal_csp_prime(
      account: @account,
      analysis: @analysis,
      start_date: @analysis.start_date,
      end_date: @analysis.end_date,
      enterprise_cross_service_discount: @analysis.enterprise_cross_service_discount,
      granularity: @analysis.granularity,
      commitment_years: @analysis.commitment_years
    )

    # save that to the analysis and redirect
    @analysis.optimal_hourly_commit = @optimize_commit_results[:value]
    @analysis.chart_data = @optimize_commit_results[:chart_data]
  end
end
