class UrlHelpers
  BASE_URL = "https://us-east-1.console.aws.amazon.com"
  COST_MANAGEMENT_PATH = "cost-management/home?region=us-east-1#"
  SAVINGS_PLANS_INVENTORY_DETAILS_PATH = "savings-plans/inventory/details"

  #   https://us-east-1.console.aws.amazon.com/cost-management/home?region=us-east-1#/savings-plans/inventory/details/arn:aws:savingsplans::274567149370:savingsplan/06577e9b-100e-4fb5-b584-5680356d4bf3
  def self.get_savings_plan_path(arn:)
    "#{BASE_URL}/#{COST_MANAGEMENT_PATH}/#{SAVINGS_PLANS_INVENTORY_DETAILS_PATH}/#{arn}"
  end

  def self.get_rds_reservation_path(arn:)
    # TODO: implement
    "#{BASE_URL}/#{COST_MANAGEMENT_PATH}/#{SAVINGS_PLANS_INVENTORY_DETAILS_PATH}/#{arn}"
  end

  def self.get_elasti_cache_reservation_path(arn:)
    # TODO: implement
    "#{BASE_URL}/#{COST_MANAGEMENT_PATH}/#{SAVINGS_PLANS_INVENTORY_DETAILS_PATH}/#{arn}"
  end
end