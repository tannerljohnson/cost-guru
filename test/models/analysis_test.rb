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
#  granularity                       :string           default("HOURLY"), not null
#  chart_data                        :jsonb            not null
#  commitment_years                  :integer          default(3), not null
#  group_by                          :jsonb
#
require "test_helper"

class AnalysisTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
