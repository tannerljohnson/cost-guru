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

    default_scope { order(created_at: :desc) }

    encrypts :iam_secret_access_key

    def is_connected?
        iam_access_key_id && iam_secret_access_key
    end
end
