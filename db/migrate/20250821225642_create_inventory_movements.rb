class CreateInventoryMovements < ActiveRecord::Migration[8.0]
  def change
    create_table :inventory_movements do |t|
      t.references :inventory, null: false, foreign_key: true
      t.string :movement_type, null: false   # tipo de movimiento: "in" | "out" | "adjustment"
      t.string :reason    # motivo del movimiento: "purchase", "sale", "return", "manual", etc.
      t.decimal :quantity, precision: 12, scale: 2, null: false  # SIEMPRE positiva; el signo lo define movement_type
      t.references :source, polymorphic: true, null: false   # referencia polimórfica a la fuente del movimiento (Purchase, Sale, etc.)
      t.string :note   # nota opcional

      t.timestamps
    end
    add_index :inventory_movements, :movement_type   # índice para consultas por tipo
    add_check_constraint :inventory_movements, "quantity > 0", name: "chk_inventory_movements_quantity_positive"   # constraint para que quantity sea siempre positiva
  end
end
