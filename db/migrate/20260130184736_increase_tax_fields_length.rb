class IncreaseTaxFieldsLength < ActiveRecord::Migration[8.0]
  def change
    change_column :companies, :tax_regime, :string, limit: 100
    change_column :companies, :cfdi_use, :string, limit: 50
  end
end
