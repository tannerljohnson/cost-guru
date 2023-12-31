class RdsClient < BaseAwsClient
  def self.describe_reserved_db_instances(account:)
    new(account: account, client_type: Constants::RDS).describe_reserved_db_instances
  end

  def describe_reserved_db_instances
    # TODO: validate this is correct
    response = client.describe_reserved_db_instances
    response.reserved_db_instances.map do |reservation|
      {
        id: reservation.reserved_db_instance_id,
        arn: reservation.reserved_db_instance_arn,
        db_instance_class: reservation.db_instance_class,
        start: reservation.start_time.to_time.utc,
        end: reservation.start_time.to_time.utc + reservation.duration,
        term_duration_in_years: reservation.duration / 60 / 60 / 24 / 365,
        db_instance_count: reservation.db_instance_count,
        product_description: reservation.product_description,
        offering_type: reservation.offering_type,
        multi_az: reservation.multi_az,
        fixed_price: reservation.fixed_price,
        state: reservation.state
      }
    end.sort { |a, b| a[:state] <=> b[:state] }
  rescue StandardError => e
    puts "Error! #{e}"
    []
  end
end