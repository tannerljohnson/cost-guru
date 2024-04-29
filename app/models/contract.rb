# == Schema Information
#
# Table name: contracts
#
#  id                       :uuid             not null, primary key
#  term_start               :datetime         not null
#  term_end                 :datetime         not null
#  cross_service_discount   :decimal(, )      not null
#  upfront_payment_discount :decimal(, )      not null
#  account_id               :uuid
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
class Contract < ApplicationRecord
  belongs_to :account
  has_many :contract_years
  has_many :service_discounts
end
