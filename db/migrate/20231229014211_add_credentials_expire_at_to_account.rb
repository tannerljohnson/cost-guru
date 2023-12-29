class AddCredentialsExpireAtToAccount < ActiveRecord::Migration[7.1]
  change_table :accounts do |t|
    t.time :credentials_expire_at
  end
end
