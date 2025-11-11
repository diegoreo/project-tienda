class AddCancellationFieldsToSales < ActiveRecord::Migration[8.0]
  def change
    # Relación con register_session (para sistema de cajas)
    add_reference :sales, :register_session, foreign_key: true
    
    # Campos adicionales de cancelación (para auditoría)
    add_column :sales, :cancelled_at, :datetime
    add_reference :sales, :cancelled_by, foreign_key: { to_table: :users }
    add_column :sales, :cancellation_reason, :text
    
    # Índices para búsquedas rápidas
    add_index :sales, :cancelled_at
    add_index :sales, [:register_session_id, :status]
    add_index :sales, [:status, :sale_date]
  end
end
