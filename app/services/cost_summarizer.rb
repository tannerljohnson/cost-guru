class CostSummarizer
  def self.summarize(account:)
    new(account: account).summarize
  end

  def initialize(account:)
    @account = account
    @granularity = Constants::DAILY
    @metrics = Constants::NET_AMORTIZED_COST
  end

  private_class_method :new
  attr_reader :account, :granularity, :metrics

  def summarize
    today = Time.now.utc
    start_of_month = today.beginning_of_month
    end_of_month = today.end_of_month + 1.day
    @this_month_current_by_day = CostAndUsageFetcher.fetch(
      account: account,
      start_date: start_of_month,
      end_date: today,
      granularity: granularity,
      filter: Constants::EXCLUDE_IGNORED_SERVICES_FILTER,
      metrics: metrics
    )
    @this_month_forecast_by_day = CostForecastFetcher.fetch(
      account: account,
      start_date: today,
      # +1 due to GMT
      end_date: end_of_month,
      filter: Constants::EXCLUDE_IGNORED_SERVICES_FILTER,
      granularity: granularity,
      metrics: ['NET_AMORTIZED_COST']
    )
    @this_month_current_services_to_ignore = CostAndUsageFetcher.fetch(
      account: account,
      start_date: start_of_month,
      end_date: end_of_month,
      granularity: granularity,
      filter: Constants::IGNORED_SERVICES_FOR_FORECAST_FILTER,
      group_by: Constants::SERVICE,
      metrics: metrics
    )

    # Async do |task|
    #   task.async {
    #     @this_month_current_by_day = CostAndUsageFetcher.fetch(
    #       account: account,
    #       start_date: start_of_month,
    #       end_date: today,
    #       granularity: granularity,
    #       filter: Constants::EXCLUDE_IGNORED_SERVICES_FILTER,
    #       metrics: metrics
    #     )
    #   }
    #   task.async {
    #     @this_month_forecast_by_day = CostForecastFetcher.fetch(
    #       account: account,
    #       start_date: today,
    #       # +1 due to GMT
    #       end_date: end_of_month,
    #       filter: Constants::EXCLUDE_IGNORED_SERVICES_FILTER,
    #       granularity: granularity,
    #       metrics: ['NET_AMORTIZED_COST']
    #     )
    #   }
    #   task.async {
    #     @this_month_current_services_to_ignore = CostAndUsageFetcher.fetch(
    #       account: account,
    #       start_date: start_of_month,
    #       end_date: end_of_month,
    #       granularity: granularity,
    #       filter: Constants::IGNORED_SERVICES_FOR_FORECAST_FILTER,
    #       group_by: Constants::SERVICE,
    #       metrics: metrics
    #     )
    #   }
    # end

    {
      this_month_current_by_day: @this_month_current_by_day,
      this_month_forecast_by_day: @this_month_forecast_by_day,
      this_month_current_services_to_ignore: @this_month_current_services_to_ignore
    }
  end
end