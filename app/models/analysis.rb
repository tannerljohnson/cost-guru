# == Schema Information
#
# Table name: analyses
#
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  id                                :uuid             not null, primary key
#  account_id                        :uuid
#  enterprise_cross_service_discount :float
#  start_date                        :datetime
#  end_date                          :datetime
#  optimal_hourly_commit             :float
#
class Analysis < ApplicationRecord
    belongs_to :account
end
