class BaseAwsClient
  def initialize(
    account:,
    start_date:,
    end_date:,
    granularity:,
    filter:,
    group_by:,
    metrics:,
    client_type:,
    enterprise_cross_service_discount: 0
  )
    @account = account
    date_str_format = granularity == Constants::HOURLY ? Constants::HOUR_FORMAT_STR : Constants::DAY_FORMAT_STR
    @start_date = start_date.strftime(date_str_format)
    @end_date = end_date.strftime(date_str_format)
    @granularity = granularity
    @filter = filter
    @group_by = group_by
    @metrics = metrics
    @client_type = client_type
    @enterprise_cross_service_discount = enterprise_cross_service_discount
  end

  private_class_method :new
  attr_reader :account, :start_date, :end_date, :granularity, :filter, :group_by, :metrics, :client, :client_type, :enterprise_cross_service_discount
  def client
    @client ||= begin
                  return unless account.is_connected?

                  Aws.config.update({ region: 'us-west-2' })
                  klass = Constants::CLIENT_CLASS_MAPPINGS[client_type]
                  klass.new(credentials: get_iam_credentials)
                end
  end

  private

  def get_iam_credentials
    # Prefer cross account role connector
    if account.cross_account_role_connected?
      credentials = get_temporary_credentials
    elsif account.iam_connected?
      credentials = Aws::Credentials.new(account.iam_access_key_id, account.iam_secret_access_key)
    else
      raise "Unknown connection"
    end

    credentials
  end

  # TODO: Save these to account as a cache. Update when expiring
  def get_temporary_credentials
    cost_guru_aws_account_credentials = Aws::Credentials.new(
      Rails.application.credentials.root_aws_account.sts_assume_role_user.iam_access_key_id,
      Rails.application.credentials.root_aws_account.sts_assume_role_user.iam_secret_access_key
    )
    sts_client = Aws::STS::Client.new(credentials: cost_guru_aws_account_credentials)
    response = sts_client.assume_role({
                                        role_arn: account.role_arn,
                                        role_session_name: "STSSession#{account.name.gsub(/\s+/, '')}#{Time.now.to_i}",
                                      })
    # Use the temporary credentials obtained from the response to make AWS Cost Explorer API requests
    Aws::Credentials.new(
      response.credentials.access_key_id,
      response.credentials.secret_access_key,
      response.credentials.session_token
    )
  end
end