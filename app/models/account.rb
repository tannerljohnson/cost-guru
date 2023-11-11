class Account < ApplicationRecord
    belongs_to :user
    has_many :analyses

    encrypts :iam_secret_access_key


    def cost_explorer_client
        return unless iam_access_key_id && iam_secret_access_key

        Aws.config.update({ region: 'us-west-2' })
        credentials = Aws::Credentials.new(iam_access_key_id, iam_secret_access_key)
        Aws::CostExplorer::Client.new(credentials: credentials)
        # response = cost_explorer_client.get_cost_and_usage({
        #     time_period: {
        #         start: '2023-01-01',
        #         end: '2023-01-31'
        #     },
        #     granularity: 'MONTHLY',
        #     metrics: ['BlendedCost'],
        #     group_by: [
        #         {
        #         type: 'DIMENSION',
        #         key: 'SERVICE'
        #         }
        #     ]
        # })
    end
end
