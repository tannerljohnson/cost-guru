class GraphHelpers
  def self.get_color_for_pct_change(pct)
    if pct < 0
      'darkseagreen'
    elsif pct < 20
      'yellow'
    elsif pct < 60
      'orange'
    else
      'indianred'
    end
  end

  def self.format_cost_and_usage_for_heat_map(cost_and_usage)
    # get all groups
    # and all dates
    all_groups = cost_and_usage.flat_map { |c| c[:groups].map { |g| g.first } }.uniq

    # transform cost_and_usage to by week
    cost_and_usage_by_week = {}
    cost_and_usage.each do |usage_from_day|
      date = usage_from_day[:start]
      week = date.to_date.beginning_of_week.to_s
      total = usage_from_day[:total]
      groups = usage_from_day[:groups].to_h

      if cost_and_usage_by_week.key?(week)
        cost_and_usage_by_week[week][:total] += total
        all_groups.each do |group_name|
          group_total = groups[group_name] || 0.0
          if cost_and_usage_by_week[week][:groups].key?(group_name)
            cost_and_usage_by_week[week][:groups][group_name] += group_total
          else
            cost_and_usage_by_week[week][:groups][group_name] = group_total
          end
        end
      else
        cost_and_usage_by_week[week] = {
          total: total,
          groups: groups
        }
      end
    end

    # TODO: group by week instead of day
    result = {}
    cost_and_usage_by_week.each do |week, data|
      data[:groups].each do |service, total|
        result[service] = [] unless result.key?(service)
        # 0 -> 0 should be 0% change
        # 0 -> N should be 100% change
        previous_total = result[service].last&.fetch(:total) || 0
        pct_change_from_previous = if previous_total == 0
                                     total == 0 ? 0.0 : 100.0
                                   else
                                     100 * ((total / previous_total) - 1)
                                   end
        result[service] << {
          date: week,
          pct_change: pct_change_from_previous,
          total: total,
          color: get_color_for_pct_change(pct_change_from_previous)
        }
      end
    end

    # remove the first week
    result = result.map { |k, v| [k, v[1..]] }.to_h
    # sort by most recent total desc
    result.sort { |a, b| b[1].last[:total] <=> a[1].last[:total] }.to_h
  end

  def self.merge_chart_cost_and_usage_data(cost_and_usages)
    # INPUT:
    # [
    #   [
    #     {name: "On Demand", data: ['2023-12-02', 109800.20]}
    #   ],
    #   [
    #     {name: "Savings Plans", data: ['2023-12-02', 109800.20]},
    #   ],
    # ]

    # OUTPUT:
    # [
    #   {
    #     name: "On Demand",
    #     data: []
    #   },
    #   {
    #     name: "Savings Plans",
    #     data: []
    #   },
    # ]
    cost_and_usages.map do |cost_and_usage|
      raise "Cost and usage for merge cannot have groups" if cost_and_usage.size > 1

      return nil if cost_and_usage.empty?

      {
        name: cost_and_usage.first[:name],
        data: cost_and_usage.first[:data]
      }
    end.compact
  end

  # series_name is applicable only if there are no groups
  def self.format_cost_and_usage_for_chart(cost_and_usage_data, series_name = "Total", start_date_override = nil)
    # INPUT
    # [
    #   {
    #   :start=>"2023-12-17",
    #   :total=>52586.96,
    #   :groups=> [
    #       ["AWS Cloud Map", 0.0],
    #       ["AWS CloudTrail", 0.0],
    #       ["AWS CodeArtifact", 0.0]
    #     ]
    #   },
    #   {
    #   :start=>"2023-12-18",
    #   :total=>586.96,
    #   :groups=> [
    #       ["AWS Cloud Map", 0.0],
    #       ["AWS CloudTrail", 0.0],
    #     ]
    #   }
    # ]
    #
    # OR
    #
    #  [{:start=>"2023-12-14", :total=>73540.25, :groups=>[]},
    #  {:start=>"2023-12-15", :total=>69740.66, :groups=>[]},
    #  {:start=>"2023-12-16", :total=>54981.15, :groups=>[]},
    #  {:start=>"2023-12-17", :total=>52586.98, :groups=>[]}]

    # OUTPUT:
    # [
    #   {name: "confluent", data: ['2023-12-02', 109800.20]},
    #   {name: "cohere", data: ['2023-12-02', 109800.20]}
    # ]
    return [] if cost_and_usage_data.empty?
    
    if cost_and_usage_data.first.fetch(:groups).empty?
      transformed_data = cost_and_usage_data.map { |result_by_time| [result_by_time.fetch(:start), result_by_time.fetch(:total)] }
      filtered_data = start_date_override ? transformed_data.filter { |date, _total| date >= start_date_override } : transformed_data

      return [
        {
          name: series_name,
          data: filtered_data,
        }
      ]
    end

    # TODO: implement start_date_override for grouped data
    result_hash = {}
    usage_keys = cost_and_usage_data.map do |result_by_time|
      result_by_time[:groups].map { |group| group[0] }
    end.flatten.uniq

    usage_keys.each do |usage_key|
      unless result_hash.key?(usage_key)
        result_hash[usage_key] = []
      end
    end

    cost_and_usage_data.each do |result_by_time|
      date = result_by_time[:start]
      result_by_time[:groups].each do |group|
        key = group[0]
        amount = group[1]

        result_hash[key] << [date, amount]
      end
    end

    results = result_hash.map do |usage_key, usage_data|
      {
        name: usage_key,
        data: usage_data
      }
    end
    return results unless usage_keys.size >= 12

    # if usage_keys.size >= 12, show 10, and collapse the remainder into an 'Other'
    # { 'Ec2': 12, 'Other': 1 }
    usage_key_totals = result_hash.map do |usage_key, usage_data|
      total = usage_data.sum { |result_by_time| result_by_time[1] }
      [usage_key, total]
    end

    # sort descending
    usage_key_totals.sort! { |a, b| b[1] <=> a[1] }
    top_usage_keys = usage_key_totals.first(10).map { |key, _total| key }

    other_usage_data_hash = {}
    results.each do |res|
      unless top_usage_keys.include?(res[:name])
        res[:data].each do |date, total|
          unless other_usage_data_hash.key?(date)
            other_usage_data_hash[date] = 0.0
          end

          other_usage_data_hash[date] += total
        end
      end
    end
    other_usage_data = other_usage_data_hash.to_a

    filtered_results = results.filter do |res|
      top_usage_keys.include?(res[:name])
    end
    filtered_results << {
      name: 'Other',
      data: other_usage_data
    }
    filtered_results
  end
end
