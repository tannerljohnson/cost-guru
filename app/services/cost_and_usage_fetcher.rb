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

  def fetch
    puts "✅ REMOTE CALL: get_cost_and_usage"
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
    begin
      response = client.get_cost_and_usage(request_body)
    rescue e
      puts "ERROR! #{e}"
    end

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