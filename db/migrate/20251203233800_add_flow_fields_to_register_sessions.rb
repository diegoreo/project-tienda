class AddFlowFieldsToRegisterSessions < ActiveRecord::Migration[8.0]
  def change
    # Contadores de flujos de efectivo
    add_column :register_sessions, :total_inflows, :decimal, precision: 10, scale: 2, default: 0.0, null: false
    add_column :register_sessions, :total_outflows, :decimal, precision: 10, scale: 2, default: 0.0, null: false
    
    # Índice para búsquedas
    add_index :register_sessions, :total_inflows
    add_index :register_sessions, :total_outflows
  end
end
