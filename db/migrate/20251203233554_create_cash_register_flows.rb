class CreateCashRegisterFlows < ActiveRecord::Migration[8.0]
  def change
    create_table :cash_register_flows do |t|
      # Relación con sesión de caja
      t.references :register_session, null: false, foreign_key: true, index: true
      
      # Tipo de movimiento (0=inflow, 1=outflow)
      t.integer :movement_type, null: false, default: 0
      
      # Monto del movimiento
      t.decimal :amount, precision: 10, scale: 2, null: false
      
      # Descripción/Motivo (obligatorio)
      t.text :description, null: false
      
      # Quién registró el movimiento
      t.references :created_by, null: false, foreign_key: { to_table: :users }, index: true
      
      # Quién autorizó el movimiento (Admin/Gerente/Supervisor)
      t.references :authorized_by, null: false, foreign_key: { to_table: :users }, index: true

      t.timestamps
    end

    # Índices adicionales para búsquedas rápidas
    add_index :cash_register_flows, :movement_type
    add_index :cash_register_flows, :created_at
    add_index :cash_register_flows, [:register_session_id, :movement_type]
  end
end
