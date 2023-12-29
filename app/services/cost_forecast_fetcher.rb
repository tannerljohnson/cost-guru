class CostForecastFetcher < BaseAwsClient
  def self.fetch(
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
    ).fetch
  end

  def fetch
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
  rescue e
    puts "ERROR!: #{e}"
  end
end