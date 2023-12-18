class CostExplorer
    CSP_DISCOUNT_RATE = 0.512

    def self.get_cost_and_usage(account:, start_date:, end_date:, granularity: "DAILY", filter: nil, group_by: nil, metrics: "NetAmortizedCost")
        new(account: account, start_date: start_date, end_date: end_date, granularity: granularity, filter: filter, group_by: group_by, metrics: metrics).get_cost_and_usage
    end

    def self.get_cost_summary(account:)
        new(account: account).get_cost_summary
    end

    def self.get_compute_savings_plans_inventory(account:)
        new(account: account).get_compute_savings_plans_inventory
    end

    def self.get_savings_plans_coverage_and_utilization(account:, start_date:, end_date:)
        new(account: account, start_date: start_date, end_date: end_date).get_savings_plans_coverage_and_utilization
    end

    def self.get_full_dataset(account:,start_date:,end_date:,enterprise_cross_service_discount:,csp_prime:)
        new(account: account, start_date: start_date, end_date: end_date, enterprise_cross_service_discount: enterprise_cross_service_discount).get_full_dataset(csp_prime)
    end

    def self.compute_optimal_csp_prime(account:, start_date:, end_date:, enterprise_cross_service_discount:, granularity:)
        new(account: account, start_date: start_date, end_date: end_date, enterprise_cross_service_discount: enterprise_cross_service_discount, granularity: granularity).compute_optimal_csp_prime
    end

    def initialize(account:, start_date: nil, end_date: nil, enterprise_cross_service_discount: nil, granularity: "DAILY", filter: nil, group_by: nil, metrics: "NetAmortizedCost")
        @account = account
        @start_date = start_date&.strftime('%Y-%m-%d')
        @end_date = end_date&.strftime('%Y-%m-%d')
        @enterprise_cross_service_discount = enterprise_cross_service_discount
        @granularity = granularity
        @filter = filter
        @group_by = group_by
        @metrics = metrics
        initialize_client
    end
    private_class_method :new

    attr_reader :account,
        :client,
        :start_date,
        :end_date,
        :enterprise_cross_service_discount,
        :granularity,
        :eligible_compute_cost_and_usage,
        :filter,
        :granularity,
        :group_by,
        :metrics

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
    def get_cost_and_usage
        today = Date.today
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
        results_hash = {}


        filtered_results = response.results_by_time.filter { |res| res.time_period.start < today.to_s }
        results = []
        filtered_results.map do |result_by_time|
            groups = result_by_time.groups.map do |group|
                [group.keys.first, group.metrics[metrics].amount.to_f.round(2)]
            end

            total = 0.0
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

    def get_cost_summary
        # TODO: Make this more performant, there are duplicative calls
        Async do |task|
            task.async { @this_month_current_by_day = get_this_month_current_by_day }
            task.async { @this_month_forecast_by_day = get_this_month_forecast_by_day }
            task.async { @this_month_current_services_to_ignore = get_this_month_current_ignored_services }
        end

        {
            this_month_current_by_day: @this_month_current_by_day,
            this_month_forecast_by_day: @this_month_forecast_by_day,
            this_month_current_services_to_ignore: @this_month_current_services_to_ignore,
            last_ninety_days: @last_ninety_days
        }
    end

    def get_this_month_current_by_day(filter: Constants::SERVICES_TO_IGNORE_FILTER, group_by: nil)
        today = Date.today
        start_of_month = today.beginning_of_month
        end_of_month = today.end_of_month + 1

        start_date = start_of_month.strftime('%Y-%m-%d')
        end_date = end_of_month.strftime('%Y-%m-%d')
        response = client.get_cost_and_usage({
            time_period: {
              start: start_date,
              end: end_date
            },
            filter: filter,
            granularity: 'DAILY',
            group_by: group_by,
            metrics: ['NetAmortizedCost']
          })


        # filter out today till end of month. this will be covered by the forecast
        cost_summary = response.results_by_time.filter do |res|
            res.time_period.start < today.to_s
        end.map do |result|
            [
                result.time_period.start,
                result.total['NetAmortizedCost'].amount.to_f.round(2)
            ]
        end
        return cost_summary
    end

    def get_this_month_current_ignored_services
        today = Date.today
        start_of_month = today.beginning_of_month
        end_of_month = today.end_of_month + 1

        start_date = start_of_month.strftime('%Y-%m-%d')
        end_date = end_of_month.strftime('%Y-%m-%d')
        response = client.get_cost_and_usage({
            time_period: {
              start: start_date,
              end: end_date
            },
            filter: {
                dimensions: {
                    key: "SERVICE", values: Constants::SERVICES_TO_IGNORE
                }
            },
            granularity: 'DAILY',
            group_by: [
                {
                  type: 'DIMENSION',
                  key: 'SERVICE'
                }
            ],
            metrics: ['NetAmortizedCost']
          })

        # [
        #   {name: "confluent", data: ['2023-12-02', 109800.20]},
        #   {name: "cohere", data: ['2023-12-02', 109800.20]}
        # ]

        # {
        #     "cohere stuff": [],
        #     "confluent stuff": [],
        # }

        results_hash = {}
        response.results_by_time.filter do |res|
            res.time_period.start < today.to_s
        end.each do |grouped_day|
            date = grouped_day.time_period.start
            grouped_day.groups.each do |group|
                key = group.keys.first
                unless results_hash.keys.include?(key)
                    results_hash[key] = []
                end
                results_hash[key] << [date, group.metrics['NetAmortizedCost'].amount.to_f.round(2)]
            end
        end

        chart_data = results_hash.map do |key, data|
            {
                name: key,
                data: data
            }
        end
        chart_data
    end

    def get_this_month_forecast_by_day
        # +1 due to GMT
        today = Date.today + 1
        end_of_month = today.end_of_month + 1

        start_date = today.strftime('%Y-%m-%d')
        end_date = end_of_month.strftime('%Y-%m-%d')

        response = client.get_cost_forecast({
            time_period: {
                start: start_date,
                end: end_date
            },
            filter: Constants::SERVICES_TO_IGNORE_FILTER,
            granularity: 'DAILY',
            metric: 'NET_AMORTIZED_COST'
        })


        response.forecast_results_by_time.map do |result|
            [
                result.time_period.start,
                result.mean_value.to_f.round(2)
            ]
        end
    end

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

        # cut it into even chunks?
        chunk_size = sorted_data_points.count / 30
        chart_data = sorted_data_points.each_with_index.filter do |data, i|
            i % 4 == 0 && data[1] > -10
        end.map { |d| d[0] }

        return {
            value: optimal,
            chart_data: chart_data
        }
    end

    def get_monthly_savings_for_dataset(dataset)
        (dataset.sum { |row| row[:savings] } * 30.4 / dataset.count).round(2)
    end

    def get_full_dataset(csp_prime_hourly)
        # TODO: Support hourly granularity
        csp_prime_daily = csp_prime_hourly * 24
        csp_prime_in_on_demand = csp_prime_daily / (1 - CSP_DISCOUNT_RATE)
        on_demand_post_discount = eligible_compute_cost_and_usage
        savings_plans = get_compute_savings_plan_spending_by_day
        rows = (Date.parse(start_date)...Date.parse(end_date)).to_a.each_with_index.map do |date, i|
            on_demand_post_discount_unit = on_demand_post_discount[i].to_f
            savings_plans_unit = savings_plans[i].to_f
            on_demand_covered_by_csp_unit = savings_plans_unit / (1 - CSP_DISCOUNT_RATE)
            on_demand_pre_discount_unit = on_demand_post_discount_unit / (1 - (enterprise_cross_service_discount / 100))
            csp_prime_plus_csp_in_on_demand = savings_plans_unit + csp_prime_in_on_demand
            total_we_spend_today_unit = on_demand_post_discount_unit + savings_plans_unit
            on_demand_pre_edp_post_csp_prime_unit = on_demand_pre_discount_unit - csp_prime_in_on_demand
            on_demand_post_edp_post_csp_prime_unit = [on_demand_pre_edp_post_csp_prime_unit * (1 - (enterprise_cross_service_discount / 100)), 0].max
            new_total_unit = savings_plans_unit + csp_prime_daily + on_demand_post_edp_post_csp_prime_unit
            {
                date: date,
                on_demand_post_discount: on_demand_post_discount_unit,
                savings_plans: savings_plans_unit,
                on_demand_covered_by_csp: on_demand_covered_by_csp_unit,
                total_on_demand_dollars: on_demand_post_discount_unit + on_demand_covered_by_csp_unit,
                coverage: (100 * on_demand_covered_by_csp_unit / (on_demand_post_discount_unit + on_demand_covered_by_csp_unit)).round(2),
                on_demand_pre_discount: on_demand_pre_discount_unit,
                total_we_spend_today: total_we_spend_today_unit,
                csp_prime: csp_prime_daily,
                csp_prime_in_on_demand: csp_prime_in_on_demand,
                csp_prime_plus_csp_in_on_demand: csp_prime_plus_csp_in_on_demand,
                on_demand_pre_edp_post_csp_prime: on_demand_pre_edp_post_csp_prime_unit,
                on_demand_post_edp_post_csp_prime: on_demand_post_edp_post_csp_prime_unit,
                new_total: new_total_unit,
                savings: total_we_spend_today_unit - new_total_unit,
                new_coverage: (100 * csp_prime_plus_csp_in_on_demand / (csp_prime_plus_csp_in_on_demand + on_demand_post_edp_post_csp_prime_unit)).round(2)
            }
        end
        rows
    end


    def eligible_compute_cost_and_usage
        # aws ce get-dimension-values --time-period Start=2022-01-01,End=2023-12-10 --dimension USAGE_TYPE --profile infrastructure-admin | jq '.DimensionValues | .[] | .Value'
        @eligible_compute_cost_and_usage ||= get_cost_and_usage_deprecated(
            start_date: start_date,
            end_date: end_date,
            filter: Constants::CSP_ELIGIBLE_COST_AND_USAGE_FILTER,
            granularity: 'DAILY',
            metrics: 'NetAmortizedCost'
        ).results_by_time.map { |result| result.total['NetAmortizedCost'].amount }
    end

    def get_compute_savings_plans_inventory
        # TODO: Add describe*, other read for savingsplan*, elasticache, rds in notion labs
        # Also might need it for other stuff
        # Need to instantiate a client for each
        # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/ElastiCache/Client.html#describe_reserved_cache_nodes-instance_method
        # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/SavingsPlans/Client.html#describe_savings_plans-instance_method
        # https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/RDS/Client.html#describe_reserved_db_instances-instance_method
        response = savings_plans_client.describe_savings_plans
        response.map do |savings_plan|
            {
                id: savings_plan.savings_plan_id,
                type: savings_plan.savings_plan_type,
                commitment: savings_plan.commitment.amount,
                start_date: savings_plan.start,
                end_date: savings_plan.end,
            }
        end
    end

    def get_savings_plans_coverage_and_utilization
        utilization_response = client.get_savings_plans_utilization({
            time_period: {
                start: start_date,
                end: end_date
            },
            granularity: 'DAILY'
        })


        utilization_data = utilization_response.savings_plans_utilizations_by_time.map do |data|
            [data.time_period.start, data.utilization.utilization_percentage.to_f]
        end

        coverage_response = client.get_savings_plans_coverage({
            time_period: {
                start: start_date,
                end: end_date
            },
            granularity: 'DAILY'
        })

        coverage_data = coverage_response.savings_plans_coverages.map do |data|
            [data.time_period.start, data.coverage.coverage_percentage.to_f.round(2)]
        end


        {
            coverage: coverage_data,
            utilization: utilization_data
        }
    end

    def get_compute_savings_plan_spending_by_day
        # Make the API call to get Compute Savings Plan utilization
        response = client.get_savings_plans_utilization({
            time_period: {
                start: start_date,
                end: end_date
            },
            granularity: 'DAILY'
        })

        # Extract and return the spending data
        spending_data = response.savings_plans_utilizations_by_time.map do |data|
            apply_enterprise_discount(data.utilization.total_commitment.to_f)
        end

        return spending_data
    end

    def apply_enterprise_discount(amount)
        amount * (1 - (enterprise_cross_service_discount / 100))
    end

    def get_cost_and_usage_deprecated(start_date:, end_date:, filter: nil, granularity: 'DAILY', metrics: 'NetAmortizedCost')
        client.get_cost_and_usage(
            time_period: {
                start: start_date,
                end: end_date
            },
            granularity: granularity,
            metrics: [metrics],
            filter: filter
        )
    end

    def savings_plans_client
        return unless account.is_connected?
        Aws.config.update({ region: 'us-west-2' })

        @savings_plans_client ||= Aws::SavingsPlans::Client.new(credentials: get_iam_credentials)
    end

    def initialize_client
        return unless account.is_connected?
        Aws.config.update({ region: 'us-west-2' })

        @client = Aws::CostExplorer::Client.new(credentials: get_iam_credentials)
    end

    def get_iam_credentials
        # Prefer cross account role connector
        if account.cross_account_role_connected?
            credentials = get_temporary_credentials
        elsif account.iam_connected?
            credentials = Aws::Credentials.new(account.iam_access_key_id, account.iam_secret_access_key)
        else
            raise "Unknown connection"
        end

        credentials
    end

    def get_temporary_credentials
        cost_guru_aws_account_credentials = Aws::Credentials.new(
            Rails.application.credentials.root_aws_account.sts_assume_role_user.iam_access_key_id,
            Rails.application.credentials.root_aws_account.sts_assume_role_user.iam_secret_access_key
        )
        sts_client = Aws::STS::Client.new(credentials: cost_guru_aws_account_credentials)
        response = sts_client.assume_role({
            role_arn: account.role_arn,
            role_session_name: "STSSession#{account.name.gsub(/\s+/, '')}#{Time.now.to_i}",
        })
        # Use the temporary credentials obtained from the response to make AWS Cost Explorer API requests
        Aws::Credentials.new(response.credentials.access_key_id, response.credentials.secret_access_key, response.credentials.session_token)
    end
end
