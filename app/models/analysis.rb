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
#  granularity                       :string           default("hourly"), not null
#  chart_data                        :jsonb            not null
#  commitment_years                  :integer          default(3), not null
#
class Analysis < ApplicationRecord
  belongs_to :account
  has_many :cost_and_usages, dependent: :destroy

  GRANULARITY_OPTIONS = [
    Constants::HOURLY,
    Constants::DAILY,
  ]
  COMMITMENT_YEARS_TO_DISCOUNT = {
    3 => 0.512,
    1 => 0.40 # todo: figure out true rate
  }
  validates :commitment_years, presence: true, inclusion: { in: COMMITMENT_YEARS_TO_DISCOUNT.keys }
  validates :granularity, presence: true, inclusion: { in: GRANULARITY_OPTIONS }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :hourly_must_be_14_days_max

  def recompute_optimal_hourly_commit!
    optimal_hourly = ComputeSavingsPlansOptimizer.compute_optimal_csp_prime(
      account: self.account,
      analysis: self,
      start_date: self.start_date,
      end_date: self.end_date,
      enterprise_cross_service_discount: self.enterprise_cross_service_discount,
      granularity: self.granularity,
      commitment_years: self.commitment_years
    )
    self.optimal_hourly_commit = optimal_hourly
    self.save!
  end

  private

  def hourly_must_be_14_days_max
    if granularity && start_date && granularity == Constants::HOURLY && start_date < (Time.now.utc - 14.days).beginning_of_day
      errors.add(:start_date, "Start date is too old for hourly, the max supported days for hourly granularity is 14 days")
    end
  end
end
