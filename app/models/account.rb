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
#  role_arn              :string
#  access_key_id         :string
#  secret_access_key     :string
#  session_token         :string
#  credentials_expire_at :string
#
class Account < ApplicationRecord
  belongs_to :user
  has_many :analyses, dependent: :destroy
  has_many :revenue_months, dependent: :destroy

  default_scope { order(created_at: :desc) }

  encrypts :iam_secret_access_key

  validate :credentials_must_all_be_set_at_once

  def type
    'aws'
  end

  def is_connected?
    cross_account_role_connected? || iam_connected?
  end

  def iam_connected?
    iam_access_key_id && iam_secret_access_key
  end

  def cross_account_role_connected?
    role_arn.present?
  end

  def connection_strategy
    if cross_account_role_connected?
      "cross_account_iam_role"
    elsif iam_connected?
      "iam_credentials"
    end
  end

  private

  def credentials_must_all_be_set_at_once
    if credentials_expire_at.present?
      errors.add(:base, "Credentials must all be set at once") unless session_token.present? && secret_access_key.present? && access_key_id.present?
    end
  end
end
