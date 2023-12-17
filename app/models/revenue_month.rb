# == Schema Information
#
# Table name: revenue_months
#
#  id         :uuid             not null, primary key
#  start_date :datetime         not null
#  revenue    :float            default(0.0), not null
#  account_id :uuid             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class RevenueMonth < ApplicationRecord
  belongs_to :account
end
