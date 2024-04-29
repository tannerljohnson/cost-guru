class ServiceDiscountsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_account!
  before_action :load_contract!

  def create
    if @contract.service_discounts.create(service_discount_params)
      # todo save contract years from params[:contract_years] (create records)
      redirect_to account_contract_path(@account, @contract)
    end
    # todo: else
  end

  def destroy
    @service_discount = @contract.service_discounts.find { |service_discount| service_discount.id === params[:id] }
    @service_discount.destroy
    flash[:notice] = "Successfully deleted!"

    redirect_to account_contract_path(@account, @contract)
  end

  private

  def service_discount_params
    params.require(:service_discount).permit(:service, :regions, :usage_type, :price, :price_unit, :contract_years)
  end
end