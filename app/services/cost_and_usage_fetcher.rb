class CostAndUsageFetcher < BaseAwsClient
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
    request_body = {
      time_period: {
        start: start_date,
        end: end_date
      },
      filter: filter,
      granularity: granularity,
      group_by: group_by ? [
        {
          type: 'DIMENSION',
          key: group_by
        }
      ] : nil,
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
  end
end