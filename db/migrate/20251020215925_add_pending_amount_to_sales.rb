class AddPendingAmountToSales < ActiveRecord::Migration[8.0]
  def change
    add_column :sales, :pending_amount, :decimal, precision: 10, scale: 2, default: 0.0, null: false
    
    # Índice para consultas de ventas pendientes
    add_index :sales, [:customer_id, :payment_status], where: "pending_amount > 0"
  end
end
