class AddCancellationFieldsToCashRegisterFlows < ActiveRecord::Migration[8.0]
  def change
    add_column :cash_register_flows, :cancelled, :boolean, default: false, null: false
    add_reference :cash_register_flows, :cancelled_by, foreign_key: { to_table: :users }
    add_column :cash_register_flows, :cancelled_at, :datetime
    add_column :cash_register_flows, :cancellation_reason, :text
    
    add_index :cash_register_flows, :cancelled
    add_index :cash_register_flows, :cancelled_at
  end
end
