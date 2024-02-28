class CostExplorerClient < BaseAwsClient
  def self.get_cost_and_usage(
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
    ).get_cost_and_usage
  end

  def self.get_cost_forecast(
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
    ).get_cost_forecast
  end

  def self.get_savings_plans_utilization(
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
    ).get_savings_plans_utilization
  end

  def self.get_savings_plans_coverage(
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
    ).get_savings_plans_coverage
  end

  def get_cost_and_usage
    # [
    #   {
    #   :start=>"2023-12-17",
    #   :total=>52586.96,
    #   :groups=> [
    #       ["AWS Cloud Map", 0.0],
    #       ["AWS CloudTrail", 0.0],
    #       ["AWS CodeArtifact", 0.0]
    #     ]
    #   }
    # ]
    #
    # OR
    #
    #  [{:start=>"2023-12-14", :total=>73540.25, :groups=>[]},
    #  {:start=>"2023-12-15", :total=>69740.66, :groups=>[]},
    #  {:start=>"2023-12-16", :total=>54981.15, :groups=>[]},
    #  {:start=>"2023-12-17", :total=>52586.98, :groups=>[]}]

    puts "✅ REMOTE CALL: get_cost_and_usage"
    request_body = {
      time_period: {
        start: start_date,
        end: end_date
      },
      filter: filter,
      granularity: granularity,
      group_by: group_by ? [group_by] : nil,
      metrics: [metrics]
    }
    response = client.get_cost_and_usage(request_body)
    filtered_results = response.results_by_time.filter do |res|
      res.time_period.start < end_date
    end

    results = []
    filtered_results.map do |result_by_time|
      groups = result_by_time.groups.map do |group|
        [group.keys.first, group.metrics[metrics].amount.to_f.round(2)]
      end

      if groups.any?
        total = groups.sum { |group| group[1] }
      else
        total = result_by_time.total[metrics].amount.to_f.round(2)
      end

      res = {
        start: result_by_time.time_period.start,
        total: total,
        groups: groups
      }
      results << res
    end

    results
  rescue StandardError => e
    puts "ERROR! #{e}"
    []
  end

  def get_cost_forecast
    puts "✅ REMOTE CALL: get_cost_forecast"
    response = client.get_cost_forecast({
                                          time_period: {
                                            start: start_date,
                                            end: end_date
                                          },
                                          filter: filter,
                                          granularity: granularity,
                                          metric: metrics[0]
                                        })

    response.forecast_results_by_time.map do |result|
      {
        start: result.time_period.start,
        total: result.mean_value.to_f.round(2),
        groups: []
      }
    end
  rescue StandardError => e
    puts "ERROR!: #{e}"
    []
  end

  def get_savings_plans_utilization
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

  def get_savings_plans_coverage
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