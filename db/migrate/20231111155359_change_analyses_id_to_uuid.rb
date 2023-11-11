class ChangeAnalysesIdToUuid < ActiveRecord::Migration[7.1]
  def change
    add_column :analyses, :uuid, :uuid, default: "gen_random_uuid()", null: false

    change_table :analyses do |t|
      t.remove :id
      t.rename :uuid, :id
    end
    execute "ALTER TABLE analyses ADD PRIMARY KEY (id);"
  end
end
