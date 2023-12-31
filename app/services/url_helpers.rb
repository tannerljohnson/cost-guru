class UrlHelpers
  CONSOLE_BASE_URL = "console.aws.amazon.com"
  COST_MANAGEMENT_PATH = "cost-management/home?region=us-east-1#"
  SAVINGS_PLANS_INVENTORY_DETAILS_PATH = "savings-plans/inventory/details"

  #   https://us-east-1.console.aws.amazon.com/cost-management/home?region=us-east-1#/savings-plans/inventory/details/arn:aws:savingsplans::274567149370:savingsplan/06577e9b-100e-4fb5-b584-5680356d4bf3
  def self.get_savings_plan_path(arn:)
    "https://#{Constants::US_EAST_1}.#{CONSOLE_BASE_URL}/#{COST_MANAGEMENT_PATH}/#{SAVINGS_PLANS_INVENTORY_DETAILS_PATH}/#{arn}"
  end

  # https://us-west-2.console.aws.amazon.com/rds/home?region=us-west-2#reserved-db-instance:ids=ri-2023-11-04-14-51-04-903
  def self.get_rds_reservation_path(id:)
    "https://#{Constants::DEFAULT_AWS_REGION}.#{CONSOLE_BASE_URL}/rds/home?region=#{Constants::DEFAULT_AWS_REGION}#reserved-db-instance:ids=#{id}"
  end

  # https://us-west-2.console.aws.amazon.com/elasticache/home?region=us-west-2#/reserved-nodes/ri-2022-03-23-20-16-14-284
  def self.get_elasti_cache_reservation_path(id:)
    "https://#{Constants::DEFAULT_AWS_REGION}.#{CONSOLE_BASE_URL}/elasticache/home?region=#{Constants::DEFAULT_AWS_REGION}#/reserved-nodes/#{id}"
  end
end