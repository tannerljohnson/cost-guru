class AddStsCredentialsToAccount < ActiveRecord::Migration[7.1]
  change_table :accounts do |t|
    t.string :access_key_id
    t.string :secret_access_key
    t.string :session_token
  end
end
