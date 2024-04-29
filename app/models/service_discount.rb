# == Schema Information
#
# Table name: service_discounts
#
#  id          :uuid             not null, primary key
#  service     :string           not null
#  regions     :jsonb            not null
#  usage_type  :string           not null
#  price       :decimal(, )      not null
#  price_unit  :string           not null
#  contract_id :uuid
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class ServiceDiscount < ApplicationRecord
  belongs_to :contract

  has_many :contract_years, through: :contract_year_service_discounts
  has_many :contract_year_service_discounts
end
