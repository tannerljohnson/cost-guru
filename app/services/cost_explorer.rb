class CostExplorer
    # This is for a 3-year no upfront commitment.
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

    def self.get_savings_plans_coverage_and_utilization(account:, start_date:, end_date:, granularity: "DAILY")
        new(account: account, start_date: start_date, end_date: end_date, granularity: granularity).get_savings_plans_coverage_and_utilization
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
    def get_cost_and_usage(overrides = {})
        group_by_key = overrides[:group_by] || group_by
        start_date_for_query = overrides[:start_date] || start_date
        end_date_for_query = overrides[:end_date] || end_date
        request_body = {
            time_period: {
              start: start_date_for_query,
              end: end_date_for_query
            },
            filter: overrides[:filter] || filter,
            granularity: overrides[:granularity] || granularity,
            group_by: group_by_key ? [
                {
                  type: 'DIMENSION',
                  key: group_by_key
                }
            ] : nil,
            metrics: [overrides[:metrics] || metrics]
        }
        response = client.get_cost_and_usage(request_body)
        results_hash = {}
        filtered_results = response.results_by_time.filter do |res|
            res.time_period.start < end_date_for_query
        end
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
        today = Time.now.utc
        tomorrow = (today + 1).strftime('%Y-%m-%d')
        start_of_month = today.beginning_of_month.strftime('%Y-%m-%d')
        end_of_month = (today.end_of_month + 1).strftime('%Y-%m-%d')
        # TODO: Make this more performant, there are duplicative calls
        # Async do |task|
        #     task.async do
        #          @this_month_current_by_day = get_cost_and_usage({
        #             filter: Constants::EXCLUDE_IGNORED_SERVICES_FILTER,
        #             start_date: start_of_month,
        #             end_date: today.strftime('%Y-%m-%d')
        #         })
        #     end
        #     task.async { @this_month_forecast_by_day = get_this_month_forecast_by_day }
        #     task.async do
        #         @this_month_current_services_to_ignore = get_cost_and_usage({
        #             start_date: start_of_month,
        #             end_date: end_of_month,
        #             filter: Constants::IGNORED_SERVICES_FOR_FORECAST_FILTER,
        #             group_by: "SERVICE"
        #         })
            #     end
        # end

        # {
        #     this_month_current_by_day: @this_month_current_by_day,
        #     this_month_forecast_by_day: @this_month_forecast_by_day,
        #     this_month_current_services_to_ignore: @this_month_current_services_to_ignore
        # }

        {
            this_month_current_by_day: get_cost_and_usage({
                filter: Constants::EXCLUDE_IGNORED_SERVICES_FILTER,
                start_date: start_of_month,
                end_date: today.strftime('%Y-%m-%d')
            }),
            this_month_forecast_by_day: get_this_month_forecast_by_day,
            this_month_current_services_to_ignore: get_cost_and_usage({
                start_date: start_of_month,
                end_date: end_of_month,
                filter: Constants::IGNORED_SERVICES_FOR_FORECAST_FILTER,
                group_by: "SERVICE"
            })
        }
    end

    def get_this_month_current_ignored_services
        today = Time.now.utc
        start_of_month = today.beginning_of_month
        end_of_month = today.end_of_month + 1

        start_date = start_of_month.strftime('%Y-%m-%d')
        end_date = end_of_month.strftime('%Y-%m-%d')


        get_cost_and_usage({
            start_date: start_date,
            end_date: end_date,
            filter: Constants::IGNORED_SERVICES_FOR_FORECAST_FILTER,
            group_by: "SERVICE"
        })
    end

    def get_this_month_forecast_by_day
        # +1 due to GMT
        today = Time.now.utc
        end_of_month = today.end_of_month + 1

        response = client.get_cost_forecast({
            time_period: {
                start: today.strftime('%Y-%m-%d'),
                end: end_of_month.strftime('%Y-%m-%d')
            },
            filter: Constants::EXCLUDE_IGNORED_SERVICES_FILTER,
            granularity: 'DAILY',
            metric: 'NET_AMORTIZED_COST'
        })


        response.forecast_results_by_time.map do |result|
            {
                start: result.time_period.start,
                total: result.mean_value.to_f.round(2),
                groups: []
            }
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
        on_demand_post_discount = get_cost_and_usage({ filter: Constants::CSP_ELIGIBLE_COST_AND_USAGE_FILTER }).map { |result_by_time| result_by_time[:total] }
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
            granularity: granularity
        })
        utilization_data = utilization_response.savings_plans_utilizations_by_time.map do |data|
            [data.time_period.start, data.utilization.utilization_percentage.to_f]
        end

        coverage_response = client.get_savings_plans_coverage({
            time_period: {
                start: start_date,
                end: end_date
            },
            granularity: granularity
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
        response.savings_plans_utilizations_by_time.map do |data|
            apply_enterprise_discount(data.utilization.total_commitment.to_f)
        end
    end

    def apply_enterprise_discount(amount)
        amount * (1 - (enterprise_cross_service_discount / 100))
    end

    def savings_plans_client
        return unless account.is_connected?
        Aws.config.update({ region: 'us-west-2' })

        @savings_plans_client ||= Aws::SavingsPlans::Client.new(credentials: get_iam_credentials)
    end

    def initialize_client
        return unless account.is_connected?
        Aws.config.update({ region: 'us-west-2' })

        @client ||= Aws::CostExplorer::Client.new(credentials: get_iam_credentials)
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
