class AddEnterpriseDiscountToAnalysis < ActiveRecord::Migration[7.1]
  def change
    change_table :analyses do |t|
      t.float :enterprise_cross_service_discount
    end
  end
end
