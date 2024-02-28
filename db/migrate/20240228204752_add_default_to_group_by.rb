class AddDefaultToGroupBy < ActiveRecord::Migration[7.1]
  def change
    change_column :analyses, :group_by, :string, default: 'NONE', null: false
  end
end
