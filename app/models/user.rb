# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  email                  :string           default(""), not null
#  first_name             :string
#  last_name              :string
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string
#  last_sign_in_ip        :string
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :accounts, dependent: :destroy
  has_many :account_memberships, dependent: :destroy

  validate :email_domain_check

  def self.from_google(email:, first_name:, last_name:)
    user = User.find_by(email: email)

    unless user
      # Set a random password for Google users
      password = Devise.friendly_token
      user = User.create!(
        email: email,
        first_name: first_name,
        last_name: last_name,
        password: password,
        password_confirmation: password,
        confirmed_at: Time.now.utc # Automatically confirm email
      )
    end

    user
  end

  private

  def email_domain_check
    unless email =~ /\A[\w+\-.]+@makenotion\.com\z/i
      errors.add(:email, "domain must be @makenotion.com")
    end
  end
end
