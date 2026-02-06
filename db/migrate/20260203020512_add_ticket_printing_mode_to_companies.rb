class AddTicketPrintingModeToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :ticket_printing_mode, :string, default: 'ask', null: false
    
    add_index :companies, :ticket_printing_mode
  end
end
