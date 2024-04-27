# == Schema Information
#
# Table name: contract_years
#
#  id               :uuid             not null, primary key
#  start_date       :datetime         not null
#  end_date         :datetime         not null
#  spend_commitment :decimal(, )      not null
#  contract_id      :uuid
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class ContractYear < ApplicationRecord
  belongs_to :contract
end
