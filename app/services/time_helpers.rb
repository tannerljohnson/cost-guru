class TimeHelpers
  def self.percentage_of_month_passed
    # Get the current date
    today = Time.now.utc

    # Get the start and end dates of the current month
    start_of_month = today.beginning_of_month
    end_of_month = today.end_of_month

    # Calculate the total days in the month
    total_days_in_month = (end_of_month - start_of_month + 1).to_i

    # Calculate the days passed so far
    days_passed = (today - start_of_month).to_i

    # Calculate the percentage of days passed
    percentage_passed = (days_passed.to_f / total_days_in_month) * 100

    return percentage_passed.round
  end

  def self.days_remaining_until(time)
    current_time_utc = Time.now.utc
    seconds_remaining = time - current_time_utc

    return 0 if seconds_remaining < 0

    (seconds_remaining / 60 / 60 / 24).to_i
  end
end
