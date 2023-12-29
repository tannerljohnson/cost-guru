class ChangeCredentialsExpireAtToString < ActiveRecord::Migration[7.1]
  def change
    change_column :accounts, :credentials_expire_at, :string
  end
end
