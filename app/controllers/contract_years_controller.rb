class ContractYearsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_account!
  before_action :load_contract!

  def create
    if @contract.contract_years.create(contract_year_params)
      redirect_to account_contract_path(@account, @contract)
    end
    # todo: else
  end

  def destroy
    @contract_year = @contract.contract_years.find { |contract_year| contract_year.id === params[:id] }
    @contract_year.destroy
    flash[:notice] = "Successfully deleted!"

    redirect_to account_contract_path(@account, @contract)
  end

  private

  def contract_year_params
    params.require(:contract_year).permit(:start_date, :end_date, :spend_commitment)
  end
end