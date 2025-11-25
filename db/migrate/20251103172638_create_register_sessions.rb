class CreateRegisterSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :register_sessions do |t|
      # Relaciones
      t.references :register, null: false, foreign_key: true
      t.references :opened_by, null: false, foreign_key: { to_table: :users }
      t.references :closed_by, foreign_key: { to_table: :users }

      # Apertura
      t.datetime :opened_at, null: false
      t.decimal :opening_balance, precision: 10, scale: 2, null: false
      t.text :opening_notes

      # Cierre
      t.datetime :closed_at
      t.decimal :closing_balance, precision: 10, scale: 2
      t.decimal :expected_balance, precision: 10, scale: 2
      t.decimal :difference, precision: 10, scale: 2
      t.text :closing_notes

      # Totales de ventas (solo ventas exitosas)
      t.decimal :total_sales, precision: 10, scale: 2, default: 0.0, null: false
      t.decimal :total_cash_sales, precision: 10, scale: 2, default: 0.0, null: false
      t.decimal :total_card_sales, precision: 10, scale: 2, default: 0.0, null: false
      t.decimal :total_credit_sales, precision: 10, scale: 2, default: 0.0, null: false
      t.integer :sales_count, default: 0, null: false

      # Ventas canceladas
      t.integer :cancelled_sales_count, default: 0, null: false
      t.decimal :cancelled_sales_total, precision: 10, scale: 2, default: 0.0, null: false

      # Estado
      t.string :status, default: 'open', null: false

      t.timestamps
    end

    # Índices
    add_index :register_sessions, [ :register_id, :closed_at ]
    add_index :register_sessions, :opened_at
    add_index :register_sessions, :status
  end
end
