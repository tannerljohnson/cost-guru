class SavingsPlansFetcher < BaseAwsClient
  def self.fetch_utilization(
    account:,
    start_date:,
    end_date:,
    granularity: Constants::DAILY,
    filter: nil,
    group_by: nil,
    metrics: Constants::NET_AMORTIZED_COST,
    enterprise_cross_service_discount: 0
  )
    new(
      account: account,
      start_date: start_date,
      end_date: end_date,
      granularity: granularity,
      filter: filter,
      group_by: group_by,
      metrics: metrics,
      client_type: Constants::COST_EXPLORER,
      enterprise_cross_service_discount: enterprise_cross_service_discount
    ).fetch_utilization
  end

  def self.fetch_coverage(
    account:,
    start_date:,
    end_date:,
    granularity: Constants::DAILY,
    filter: nil,
    group_by: nil,
    metrics: Constants::NET_AMORTIZED_COST
  )
    new(
      account: account,
      start_date: start_date,
      end_date: end_date,
      granularity: granularity,
      filter: filter,
      group_by: group_by,
      metrics: metrics,
      client_type: Constants::COST_EXPLORER
    ).fetch_coverage
  end

  def fetch_utilization
    puts "✅ REMOTE CALL: get_savings_plans_utilization"
    response = client.get_savings_plans_utilization({
                                                      time_period: {
                                                        start: start_date,
                                                        end: end_date
                                                      },
                                                      granularity: granularity
                                                    })
    response.savings_plans_utilizations_by_time.map do |data|
      {
        start: data.time_period.start,
        total: data.utilization.total_commitment.to_f * (1 - (enterprise_cross_service_discount / 100)),
        percentage: data.utilization.utilization_percentage.to_f
      }
    end
  rescue StandardError => e
    puts "Error! #{e}"
    []
  end

  def fetch_coverage
    puts "✅ REMOTE CALL: get_savings_plans_coverage"
    response = client.get_savings_plans_coverage({
                                                   time_period: {
                                                     start: start_date,
                                                     end: end_date
                                                   },
                                                   granularity: granularity
                                                 })
    response.savings_plans_coverages.map do |data|
      {
        start: data.time_period.start,
        percentage: data.coverage.coverage_percentage.to_f
      }
    end
  rescue StandardError => e
    puts "Error! #{e}"
    []
  end
end