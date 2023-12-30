class ElastiCacheClient < BaseAwsClient
  def self.describe_reserved_cache_nodes(account:)
    new(account: account, client_type: Constants::ELASTI_CACHE).describe_reserved_cache_nodes
  end

  def describe_reserved_cache_nodes
    response = client.describe_reserved_cache_nodes
    response.reserved_cache_nodes.map do |reservation|
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