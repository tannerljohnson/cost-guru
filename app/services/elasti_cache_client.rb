class ElastiCacheClient < BaseAwsClient
  def self.describe_reserved_cache_nodes(account:)
    new(account: account, client_type: Constants::ELASTI_CACHE).describe_reserved_cache_nodes
  end

  def describe_reserved_cache_nodes
    response = client.describe_reserved_cache_nodes
    response.reserved_cache_nodes.map do |reservation|
      {
        id: reservation.reserved_cache_node_id,
        cache_node_type: reservation.cache_node_type,
        arn: reservation.reservation_arn,
        start: reservation.start_time.to_time.utc,
        end: reservation.start_time.to_time.utc + reservation.duration,
        term_duration_in_years: reservation.duration / 60 / 60 / 24 / 365,
        fixed_price: reservation.fixed_price,
        cache_node_count: reservation.cache_node_count,
        product_description: reservation.product_description,
        offering_type: reservation.offering_type,
        state: reservation.state
      }
    end.sort { |a, b| a[:state] <=> b[:state] }
  rescue StandardError => e
    puts "Error! #{e}"
    []
  end
end