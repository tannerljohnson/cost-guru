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
require "test_helper"

class AnalysisTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
