class AnalysesController < ApplicationController
  before_action :authenticate_user!

  def index
    @account = Account.find(params[:account_id])
    @analyses = Analysis.where(account: @account)
  end

  def new
    @account = Account.find(params[:account_id])
    @analysis = Analysis.new(account: @account)
  end

  def create
    @account = Account.find(params[:account_id])
    @analysis = Analysis.new(
      account: @account, 
      start_date: params[:analysis][:start_date], 
      end_date: params[:analysis][:end_date], 
      enterprise_cross_service_discount: params[:analysis][:enterprise_cross_service_discount]
    )
    if @analysis.save
      redirect_to account_analyses_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @account = Account.find(params[:account_id])
    @analysis = @account.analyses.find { |a| a.id === params[:id] }
    if @analysis.optimal_hourly_commit.present?
      @optimal_csp_prime = @analysis.optimal_hourly_commit  
    else
      @optimal_csp_prime = CostExplorer.compute_optimal_csp_prime(account: @account, start_date: @analysis.start_date, end_date: @analysis.end_date, enterprise_cross_service_discount: @analysis.enterprise_cross_service_discount)  
      # Cache result
      @analysis.optimal_hourly_commit = @optimal_csp_prime
      @analysis.save!
    end
    @full_dataset = CostExplorer.get_full_dataset(account: @account, start_date: @analysis.start_date, end_date: @analysis.end_date, enterprise_cross_service_discount: @analysis.enterprise_cross_service_discount, csp_prime: @optimal_csp_prime)
  end
end
