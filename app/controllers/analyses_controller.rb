class AnalysesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_account!

  def index
    @analyses = @account.analyses.order(created_at: :desc)
  end

  def new
    @analysis = @account.analyses.new(
      start_date: Date.today.beginning_of_month, 
      end_date: Date.today,
      enterprise_cross_service_discount: @account.analyses.last.enterprise_cross_service_discount
    )
  end

  def create
    @analysis = @account.analyses.new(analysis_params)
    @optimal_csp_prime = CostExplorer.compute_optimal_csp_prime(
      account: @account, 
      start_date: @analysis.start_date, 
      end_date: @analysis.end_date, 
      enterprise_cross_service_discount: @analysis.enterprise_cross_service_discount,
      granularity: @analysis.granularity
    )
    @analysis.optimal_hourly_commit = @optimal_csp_prime
    if @analysis.save
      redirect_to account_analysis_path(@account, @analysis)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @analysis = @account.analyses.find { |a| a.id === params[:id] }
    @full_dataset = CostExplorer.get_full_dataset(
      account: @account, 
      start_date: @analysis.start_date, 
      end_date: @analysis.end_date, 
      enterprise_cross_service_discount: @analysis.enterprise_cross_service_discount, 
      csp_prime: @analysis.optimal_hourly_commit
    )
    @last_ninety_days = CostExplorer.get_cost_summary(account: @account).fetch(:last_ninety_days)
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
