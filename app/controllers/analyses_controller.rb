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
    @analysis = Analysis.new(account: @account)
    @analysis.source_file.attach(params[:analysis][:source_file])
    if @analysis.save
      redirect_to account_analyses_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @account = Account.find(params[:account_id])
    @analysis = @account.analyses.find { |a| a.id === params[:id] }
  end
end
