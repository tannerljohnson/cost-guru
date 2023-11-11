class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, 
         :omniauthable, omniauth_providers: [:google_oauth2]


  has_many :accounts


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
end
