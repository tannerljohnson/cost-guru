class ComputeSavingsPlansOptimizer
  # This is for a 3-year no upfront commitment.
  CSP_DISCOUNT_RATE = 0.512

  def self.get_full_dataset(
    account:,
    analysis:,
    start_date:,
    end_date:,
    enterprise_cross_service_discount:,
    csp_prime:,
    granularity:
  )
    new(
      account: account,
      analysis: analysis,
      start_date: start_date,
      end_date: end_date,
      enterprise_cross_service_discount: enterprise_cross_service_discount,
      granularity: granularity
    ).get_full_dataset(csp_prime)
  end

  def self.compute_optimal_csp_prime(
    account:,
    analysis:,
    start_date:,
    end_date:,
    enterprise_cross_service_discount:,
    granularity:
  )
    new(
      account: account,
      analysis: analysis,
      start_date: start_date,
      end_date: end_date,
      enterprise_cross_service_discount: enterprise_cross_service_discount,
      granularity: granularity
    ).compute_optimal_csp_prime
  end

  def initialize(account:, analysis: nil, start_date: nil, end_date: nil, enterprise_cross_service_discount: nil, granularity: "DAILY", filter: nil, group_by: nil, metrics: "NetAmortizedCost")
    @account = account
    @analysis = analysis
    date_str_format = granularity == Constants::HOURLY ? Constants::HOUR_FORMAT_STR : Constants::DAY_FORMAT_STR
    @start_date = start_date&.strftime(date_str_format)
    @end_date = end_date&.strftime(date_str_format)
    @enterprise_cross_service_discount = enterprise_cross_service_discount
    @granularity = granularity
    @filter = filter
    @group_by = group_by
    @metrics = metrics
  end

  private_class_method :new

  attr_reader :account,
              :analysis,
              :client,
              :start_date,
              :end_date,
              :enterprise_cross_service_discount,
              :granularity,
              :filter,
              :granularity,
              :group_by,
              :metrics,
              :csp_eligible_cost_and_usages,
              :savings_plans_cost_and_usages

  def compute_optimal_csp_prime
    # Binary search
    low = 0.0
    high = 10_000.0
    epsilon = 1e-3
    data_points = []

    while (high - low) > epsilon
      puts "Running binary search #{low} to #{high}"
      mid1 = low + (high - low) / 3
      mid2 = high - (high - low) / 3

      mid1_savings = get_monthly_savings_for_dataset(get_full_dataset(mid1))
      mid2_savings = get_monthly_savings_for_dataset(get_full_dataset(mid2))
      data_points << [mid1, mid1_savings]
      data_points << [mid2, mid2_savings]

      if mid1_savings > mid2_savings
        high = mid2
      else
        low = mid1
      end
    end

    optimal = (low + high) / 2
    optimal_savings = get_monthly_savings_for_dataset(get_full_dataset(optimal))
    data_points << [optimal, optimal_savings]
    sorted_data_points = data_points.sort_by { |data| data[0] }

    chart_data = sorted_data_points.each_with_index.filter do |data, i|
      i % 4 == 0 && data[1] > -10
    end.map { |d| d[0] }

    {
      value: optimal,
      chart_data: chart_data
    }
  end

  def get_monthly_savings_for_dataset(dataset)
    (dataset.sum { |row| row[:savings] } * Constants::AVG_DAYS_IN_MONTH / dataset.count).round(2)
  end

  def get_full_dataset(csp_prime_hourly)
    csp_prime_for_time_unit = case granularity
                              when Constants::HOURLY
                                csp_prime_hourly
                              when Constants::DAILY
                                csp_prime_hourly * 24
                              when Constants::MONTHLY
                                csp_prime_hourly * 24 * Constants::AVG_DAYS_IN_MONTH
                              else
                                raise "Invalid granularity #{granularity}"
                              end

    csp_prime_in_on_demand = csp_prime_for_time_unit / (1 - CSP_DISCOUNT_RATE)
    date_rows = case granularity
                when Constants::HOURLY
                  start_datetime = DateTime.parse(start_date)
                  end_datetime = DateTime.parse(end_date)

                  datetimes = []
                  current_datetime = start_datetime
                  while current_datetime < end_datetime
                    datetimes << current_datetime
                    current_datetime += 1.hour
                  end
                  datetimes
                when Constants::DAILY
                  (Date.parse(start_date)...Date.parse(end_date)).to_a
                else
                  # TODO implement monthly? maybe.
                  []
                end

    date_rows.each_with_index.map do |date, i|
      on_demand_post_discount_unit = csp_eligible_cost_and_usages[i].to_f
      savings_plans_unit = savings_plans_cost_and_usages[i].to_f
      on_demand_covered_by_csp_unit = savings_plans_unit / (1 - CSP_DISCOUNT_RATE)
      on_demand_pre_discount_unit = on_demand_post_discount_unit / (1 - (enterprise_cross_service_discount / 100))
      csp_prime_plus_csp_in_on_demand = csp_prime_in_on_demand + on_demand_covered_by_csp_unit
      total_we_spend_today_unit = on_demand_post_discount_unit + savings_plans_unit
      on_demand_pre_edp_post_csp_prime_unit = on_demand_pre_discount_unit - csp_prime_in_on_demand
      on_demand_post_edp_post_csp_prime_unit = [on_demand_pre_edp_post_csp_prime_unit * (1 - (enterprise_cross_service_discount / 100)), 0].max
      new_total_unit = savings_plans_unit + csp_prime_for_time_unit + on_demand_post_edp_post_csp_prime_unit
      {
        date: date,
        on_demand_post_discount: on_demand_post_discount_unit,
        savings_plans: savings_plans_unit,
        on_demand_covered_by_csp: on_demand_covered_by_csp_unit,
        total_on_demand_dollars: on_demand_post_discount_unit + on_demand_covered_by_csp_unit,
        coverage: (100 * on_demand_covered_by_csp_unit / (on_demand_post_discount_unit + on_demand_covered_by_csp_unit)).round(2),
        on_demand_pre_discount: on_demand_pre_discount_unit,
        total_we_spend_today: total_we_spend_today_unit,
        csp_prime: csp_prime_for_time_unit,
        csp_prime_in_on_demand: csp_prime_in_on_demand,
        csp_prime_plus_csp_in_on_demand: csp_prime_plus_csp_in_on_demand,
        on_demand_pre_edp_post_csp_prime: on_demand_pre_edp_post_csp_prime_unit,
        on_demand_post_edp_post_csp_prime: on_demand_post_edp_post_csp_prime_unit,
        new_total: new_total_unit,
        savings: total_we_spend_today_unit - new_total_unit,
        new_coverage: (100 * csp_prime_plus_csp_in_on_demand / (csp_prime_plus_csp_in_on_demand + on_demand_post_edp_post_csp_prime_unit)).round(2)
      }
    end
  end

  def csp_eligible_cost_and_usages
    @csp_eligible_cost_and_usages ||= analysis.nil? ? [] : analysis.cost_and_usages.where(filter: "csp_eligible").order(:start).pluck(:total)
  end

  def savings_plans_cost_and_usages
    @savings_plans_cost_and_usage ||= analysis.nil? ? [] : analysis.cost_and_usages.where(filter: "csp_payment").order(:start).pluck(:total)
  end
end
