class SavingsPlansClient < BaseAwsClient
  def self.describe_savings_plans(account:)
    new(account: account, client_type: Constants::SAVINGS_PLANS).describe_savings_plans
  end

  def describe_savings_plans
    response = client.describe_savings_plans
    response.savings_plans.map do |savings_plan|
      {
        id: savings_plan.savings_plan_id,
        arn: savings_plan.savings_plan_arn,
        description: savings_plan.description,
        start: savings_plan.start.to_time.utc,
        end: savings_plan.end.to_time.utc,
        state: savings_plan.state,
        payment_option: savings_plan.payment_option,
        commitment: savings_plan.commitment.to_f,
        product_types: savings_plan.product_types,
        term_duration_in_years: savings_plan.term_duration_in_seconds / 60 / 60 / 24 / 365
      }
    end
  rescue StandardError => e
    puts "Error! #{e}"
    []
  end
end