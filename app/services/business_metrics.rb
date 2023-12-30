class BusinessMetrics
  def self.compute_spend_as_percent_of_revenue(spend_by_month, revenue_by_month)
    return [] if spend_by_month.empty?

    spend_data = spend_by_month.first[:data].map { |date, total| [date.to_s, total] }.to_h
    revenue_data = revenue_by_month.first[:data].map { |date, total| [date.to_s, total] }.to_h

    pct_revenue_data = {}
    revenue_data.each do |rev_date, rev_total|
      pct_revenue_data[rev_date] = (spend_data[rev_date] / rev_total) * 100
    end

    [{
       name: "Spend as % of Revenue",
       data: pct_revenue_data.to_a
     }]
  end
end
