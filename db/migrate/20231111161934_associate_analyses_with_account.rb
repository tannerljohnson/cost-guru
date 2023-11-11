class AssociateAnalysesWithAccount < ActiveRecord::Migration[7.1]
  def change
    change_table :analyses do |t|
      t.references :account, type: :uuid
    end
  end
end
