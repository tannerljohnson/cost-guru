# == Schema Information
#
# Table name: accounts
#
#  id                    :uuid             not null, primary key
#  name                  :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  user_id               :uuid
#  iam_access_key_id     :string
#  iam_secret_access_key :string
#
class Account < ApplicationRecord
    belongs_to :user
    has_many :analyses, dependent: :destroy

    encrypts :iam_secret_access_key

    def is_connected?
        iam_access_key_id && iam_secret_access_key
    end


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
