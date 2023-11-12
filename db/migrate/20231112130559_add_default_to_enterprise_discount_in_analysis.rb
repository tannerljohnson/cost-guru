class AddDefaultToEnterpriseDiscountInAnalysis < ActiveRecord::Migration[7.1]
  def change
    change_column_default :analyses, :enterprise_cross_service_discount, 0.0
  end
end
