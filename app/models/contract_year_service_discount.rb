class ContractYearServiceDiscount < ApplicationRecord
  belongs_to :service_discount
  belongs_to :contract_year
end