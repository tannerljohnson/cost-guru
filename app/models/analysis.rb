# == Schema Information
#
# Table name: analyses
#
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  id                                :uuid             not null, primary key
#  account_id                        :uuid
#  enterprise_cross_service_discount :float            default(0.0), not null
#  start_date                        :datetime
#  end_date                          :datetime
#  optimal_hourly_commit             :float
#  granularity                       :string           default("daily"), not null
#  chart_data                        :jsonb            not null
#
class Analysis < ApplicationRecord
    belongs_to :account
    default_scope { order(created_at: :desc) }

    GRANULARITY_OPTIONS = [
        'daily',
        # 'hourly',
        # 'monthly'
    ]


    def recompute_optimal_hourly_commit!
        optimal_hourly = CostExplorer.compute_optimal_csp_prime(
            account: self.account, 
            start_date: self.start_date, 
            end_date: self.end_date, 
            enterprise_cross_service_discount: self.enterprise_cross_service_discount,
            granularity: self.granularity
        )
        self.optimal_hourly_commit = optimal_hourly
        self.save!
    end
end
