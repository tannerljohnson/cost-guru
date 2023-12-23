# == Schema Information
#
# Table name: cost_and_usages
#
#  id          :uuid             not null, primary key
#  start       :datetime         not null
#  analysis_id :uuid             not null
#  filter      :string           not null
#  total       :float            default(0.0), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class CostAndUsage < ApplicationRecord
  belongs_to :analysis
end
