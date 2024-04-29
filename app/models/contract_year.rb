# == Schema Information
#
# Table name: contract_years
#
#  id                  :uuid             not null, primary key
#  start_date          :datetime         not null
#  end_date            :datetime         not null
#  spend_commitment    :decimal(, )      not null
#  contract_id         :uuid
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  service_discount_id :uuid
#
class ContractYear < ApplicationRecord
  belongs_to :contract
  has_many :service_discounts, through: :contract_year_service_discounts
  has_many :contract_year_service_discounts
end
