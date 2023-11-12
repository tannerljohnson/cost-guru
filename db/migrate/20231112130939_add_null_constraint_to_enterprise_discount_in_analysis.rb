class AddNullConstraintToEnterpriseDiscountInAnalysis < ActiveRecord::Migration[7.1]
  def change
    change_column_null :analyses, :enterprise_cross_service_discount, false
  end
end
