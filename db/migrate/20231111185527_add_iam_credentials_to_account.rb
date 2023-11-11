class AddIamCredentialsToAccount < ActiveRecord::Migration[7.1]
  def change
    change_table :accounts do |t|
      t.string :iam_access_key_id
      t.string :iam_secret_access_key
    end
  end
end
