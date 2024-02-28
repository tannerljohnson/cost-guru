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
#  groups      :jsonb
#
class CostAndUsage < ApplicationRecord
  belongs_to :analysis

  before_save :strip_group_prefixes
  before_save :reduce_groups

  private

  def strip_group_prefixes
    unless self.groups.empty?
      self.groups = self.groups.map do |group_name, total|
        [group_name.split("$")[1] || "none", total]
      end
    end
  end

  def reduce_groups
    unless self.groups.empty?
      res = {}
      self.groups.each do |group_name, total|
        unless res.key?(group_name.downcase)
          res[group_name.downcase] = 0
        end
        res[group_name.downcase] += total
      end
      self.groups = res.to_a
    end
  end
end
