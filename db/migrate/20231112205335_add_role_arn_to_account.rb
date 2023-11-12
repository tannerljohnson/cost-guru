class AddRoleArnToAccount < ActiveRecord::Migration[7.1]
  def change
    change_table :accounts do |t|
      t.string :role_arn
    end
  end
end
