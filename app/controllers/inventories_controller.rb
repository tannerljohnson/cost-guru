class InventoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_account!

  def index
    @savings_plans = SavingsPlansClient.describe_savings_plans(account: @account)
    @rds_reservations = RdsClient.describe_reserved_db_instances(account: @account)
    @elasti_cache_reservations = ElastiCacheClient.describe_reserved_cache_nodes(account: @account)
  end
end