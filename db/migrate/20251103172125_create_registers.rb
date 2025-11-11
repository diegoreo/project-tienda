class CreateRegisters < ActiveRecord::Migration[8.0]
  def change
    create_table :registers do |t|
      # Identificación
      t.string :code, null: false
      t.string :name, null: false
      t.text :description
      
      # Configuración
      t.decimal :initial_balance, precision: 10, scale: 2, default: 0.0, null: false
      t.string :location
      
      # Relación con Warehouse
      t.references :warehouse, null: false, foreign_key: true
      
      # Estado
      t.boolean :active, default: true, null: false
      
      # Auditoría
      t.timestamps
    end
    
    # Índices para búsquedas rápidas
    add_index :registers, :code, unique: true
    add_index :registers, :active
    add_index :registers, [:warehouse_id, :active]
  end
end
