class ContractsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_account!

  def index
    @contracts = @account.contracts
  end

  def new
    @contract = @account.contracts.new
  end

  def edit
    @contract = @account.contracts.find { |contract| contract.id == params[:id] }
  end

  def create
    @contract = @account.contracts.new(contract_params)
    if @contract.save
      redirect_to account_contract_path(@account, @contract)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @contract = @account.contracts.find { |contract| contract.id === params[:id] }
    if @contract.update(contract_params)
      redirect_to account_contract_path(@account, @contract)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contract = @account.contracts.find { |contract| contract.id === params[:id] }
    @contract.destroy
    flash[:notice] = "Successfully deleted!"

    redirect_to account_contracts_path(@account)
  end

  def show
    @contract = @account.contracts.find { |contract| contract.id == params[:id] }
  end

  private

  def contract_params
    params.require(:contract).permit(:term_start, :term_end, :cross_service_discount, :upfront_payment_discount)
  end
end