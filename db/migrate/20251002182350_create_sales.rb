class CreateSales < ActiveRecord::Migration[8.0]
  def change
    create_table :sales do |t|
      t.references :customer, foreign_key: true, null: true # null para ventas sin cliente
      t.bigint :user_id # Sin foreign key por ahora  # quien hizo la venta
      t.references :warehouse, null: false, foreign_key: true
      t.date :sale_date, null: false
      t.decimal :total, precision: 10, scale: 2, default: 0.0, null: false
      t.integer :payment_status, default: 0, null: false
      t.integer :payment_method, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.text :notes

      t.timestamps
    end

    add_index :sales, :sale_date
    add_index :sales, :payment_status
    add_index :sales, :status
    add_index :sales, :user_id # Agregar índice manual
  end
end
