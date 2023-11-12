class CostExplorer
    CSP_DISCOUNT_RATE = 0.51
    
    def self.get_cost_summary(account:)
        new(account: account).get_cost_summary
    end

    def self.get_compute_savings_plans_inventory(account:)
        new(account: account).get_compute_savings_plans_inventory
    end

    def self.get_compute_savings_plan_spending_by_day(account:, start_date:, end_date:)
        new(account: account, start_date: start_date, end_date: end_date).get_compute_savings_plan_spending_by_day
    end

    def self.get_cost_and_usage(account:, start_date:, end_date:)
        new(account: account, start_date: start_date, end_date: end_date).get_cost_and_usage
    end

    def self.get_full_dataset(account:, start_date:, end_date:, enterprise_cross_service_discount:, csp_prime:)
        new(account: account, start_date: start_date, end_date: end_date, enterprise_cross_service_discount: enterprise_cross_service_discount).get_full_dataset(csp_prime)
    end

    def self.compute_optimal_csp_prime(account:, start_date:, end_date:, enterprise_cross_service_discount:)
        new(account: account, start_date: start_date, end_date: end_date, enterprise_cross_service_discount: enterprise_cross_service_discount).compute_optimal_csp_prime
    end

    def initialize(account:, start_date: nil, end_date: nil, enterprise_cross_service_discount: nil)
        @account = account
        @start_date = start_date.strftime('%Y-%m-%d') 
        @end_date = end_date.strftime('%Y-%m-%d')
        @enterprise_cross_service_discount = enterprise_cross_service_discount || 0
        initialize_client
    end
    private_class_method :new

    attr_reader :account, :client, :start_date, :end_date, :enterprise_cross_service_discount

    def get_cost_summary
        {
            this_month_current: get_this_month_current,
            this_month_forecast: get_this_month_forecast,
        }
    end

    def get_this_month_current
        today = Date.today
        start_of_month = today.beginning_of_month
        end_of_month = today.end_of_month

        start_date = start_of_month.strftime('%Y-%m-%d')
        end_date = end_of_month.strftime('%Y-%m-%d')
        response = client.get_cost_and_usage({
            time_period: {
              start: start_date,
              end: end_date
            },
            granularity: 'MONTHLY',
            metrics: ['AMORTIZED_COST']
          })

        cost_summary = response.results_by_time[0].total['AmortizedCost'].amount.to_f
        return cost_summary
    end

    def get_this_month_forecast
        today = Date.today
        response = client.get_cost_forecast({
            time_period: {
                start: today.strftime('%Y-%m-%d'),
                end: (today + 1.month).strftime('%Y-%m-%d') # Forecast for the next month
            },
            granularity: 'MONTHLY',
            metric: 'AMORTIZED_COST'
        })
    
        # Extract and return the projected cost
        projected_cost = response.total.amount.to_f
        return projected_cost
    end

    def compute_optimal_csp_prime
        # Binary search
        low = 0.0
        high = 10_000.0
        epsilon = 1e-3

        while (high - low) > epsilon
            mid1 = low + (high - low) / 3
            mid2 = high - (high - low) / 3
        
            if get_monthly_savings_for_dataset(get_full_dataset(mid1)) > get_monthly_savings_for_dataset(get_full_dataset(mid2))
              high = mid2
            else
              low = mid1
            end
        end
        
        optimal = (low + high) / 2
        return optimal
    end

    def get_monthly_savings_for_dataset(dataset)
        dataset.sum { |row| row[:savings] } * 30.4 / dataset.count
    end

    def get_full_dataset(csp_prime)
        csp_prime_in_on_demand = csp_prime / (1 - CSP_DISCOUNT_RATE)
        on_demand_post_discount = get_cost_and_usage
        savings_plans = get_compute_savings_plan_spending_by_day
        rows = (Date.parse(start_date)...Date.parse(end_date)).to_a.each_with_index.map do |date, i|
            on_demand_post_discount_unit = on_demand_post_discount[i].to_f
            savings_plans_unit = savings_plans[i].to_f
            on_demand_covered_by_csp_unit = savings_plans_unit / (1 - CSP_DISCOUNT_RATE)
            on_demand_pre_discount_unit = on_demand_post_discount_unit / (1 - (enterprise_cross_service_discount / 100))
            total_we_spend_today_unit = on_demand_post_discount_unit + savings_plans_unit
            on_demand_pre_edp_post_csp_prime_unit = on_demand_pre_discount_unit - csp_prime_in_on_demand
            on_demand_post_edp_post_csp_prime_unit = [on_demand_pre_edp_post_csp_prime_unit * (1 - (enterprise_cross_service_discount / 100)), 0].max
            new_total_unit = savings_plans_unit + csp_prime + on_demand_post_edp_post_csp_prime_unit
            {
                date: date,
                on_demand_post_discount: on_demand_post_discount_unit,
                savings_plans: savings_plans_unit,
                on_demand_covered_by_csp: on_demand_covered_by_csp_unit,
                total_on_demand_dollars: on_demand_post_discount_unit + on_demand_covered_by_csp_unit,
                coverage: (100 * on_demand_covered_by_csp_unit / (on_demand_post_discount_unit + on_demand_covered_by_csp_unit)).round(2),
                on_demand_pre_discount: on_demand_pre_discount_unit,
                total_we_spend_today: total_we_spend_today_unit,
                csp_prime: csp_prime,
                csp_prime_in_on_demand: csp_prime_in_on_demand,
                on_demand_pre_edp_post_csp_prime: on_demand_pre_edp_post_csp_prime_unit,
                on_demand_post_edp_post_csp_prime: on_demand_post_edp_post_csp_prime_unit,
                new_total: new_total_unit,
                savings: total_we_spend_today_unit - new_total_unit,
                new_coverage: (100 * csp_prime_in_on_demand / (csp_prime_in_on_demand + on_demand_post_edp_post_csp_prime_unit)).round(2)
            }
        end
        rows
    end

    def get_cost_and_usage
        filters = [
            { dimensions: { key: "PURCHASE_TYPE", values: ["On Demand Instances"] } },
            { dimensions: { key: "SERVICE", values: ["Amazon Elastic Compute Cloud - Compute", "AWS Lambda"] } },
            # { dimensions: { key: "USAGE_TYPE", exclude_values: ["AP-DataTransfer-Out-Bytes"] } }
          ]
        response = client.get_cost_and_usage({
            time_period: { 
                start: start_date, 
                end: end_date 
            },
            granularity: 'DAILY',
            metrics: ['NetAmortizedCost'],
            filter: { 
                and: filters
            },
        })

        response.results_by_time.map do |result|
            result.total['NetAmortizedCost'].amount
        end
    end

    def get_compute_savings_plans_inventory
        return []
        
        # Specify the time period for which you want to retrieve the inventory
        start_date = (Date.today - 30).strftime('%Y-%m-%d') # Replace with your desired start date
        end_date = Date.today.strftime('%Y-%m-%d')

        # Make the API call to get Compute Savings Plan inventory
        response = client.get_savings_plans_utilization({
            time_period: {
                start: start_date,
                end: end_date
            },
            granularity: 'MONTHLY'
            # You can add more parameters as needed
        })

        # Extract and return the inventory information
        inventory_data = response.savings_plans_utilizations_by_time
        return inventory_data
    end

    def get_compute_savings_plan_spending_by_day
        # Temporary - delete me
        fake_data = (Date.parse(start_date)..Date.parse(end_date)).to_a.map do |date|
            {
                time_period: {
                    start: date.to_s,
                    end:  (date + 1).to_s
                },
                total: {
                    "NetAmortizedCost": {
                        amount: "10.0000000",
                        unit: "USD"
                    }
                },
                groups: [],
                estimated: true
            }
        end
        return fake_data.map do |result|
            result[:total][:NetAmortizedCost][:amount]
        end

        # Make the API call to get Compute Savings Plan utilization
        response = client.get_savings_plans_utilization({
            time_period: {
                start: start_date,
                end: end_date
            },
            granularity: 'DAILY'
        })

        # Extract and return the spending data
        spending_data = response.savings_plans_utilizations_by_time
        return spending_data
    end

    def initialize_client
        return unless account.iam_access_key_id && account.iam_secret_access_key

        Aws.config.update({ region: 'us-west-2' })
        credentials = Aws::Credentials.new(account.iam_access_key_id, account.iam_secret_access_key)
        @client = Aws::CostExplorer::Client.new(credentials: credentials)
    end
end