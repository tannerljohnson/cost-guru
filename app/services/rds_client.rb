class RdsClient < BaseAwsClient
  def self.describe_reserved_db_instances(account:)
    new(account: account, client_type: Constants::RDS).describe_reserved_db_instances
  end

  def describe_reserved_db_instances
    # TODO: validate this is correct
    response = client.describe_reserved_db_instances
    response.reserved_db_instances.map do |reservation|
      {
        id: reservation.reservation_id,
        arn: reservation.reservation_arn,
        description: reservation.description,
        start: reservation.start.to_time.utc,
        end: reservation.end.to_time.utc,
        state: reservation.state,
        payment_option: reservation.payment_option,
        commitment: reservation.commitment.to_f,
        product_types: reservation.product_types,
        term_duration_in_years: reservation.term_duration_in_seconds / 60 / 60 / 24 / 365
      }
    end
  rescue StandardError => e
    puts "Error! #{e}"
    []
  end
end