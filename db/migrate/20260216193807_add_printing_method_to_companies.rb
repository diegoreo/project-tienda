class AddPrintingMethodToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :printing_method, :string, default: 'webusb', null: false
  end
end
