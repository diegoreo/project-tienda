class CreateInventories < ActiveRecord::Migration[8.0]
  def change
    create_table :inventories do |t|
      t.references :product, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
       # cantidades en unidad de venta
      t.decimal :quantity, precision: 12, scale: 2, default: 0, null: false
      t.decimal :minimum_quantity, precision: 12, scale: 2, default: 0, null: false
      # ubicación física dentro del almacén (ej: "pasillo 3, estante B")
      t.string :location

      t.timestamps
    end
    # evitar duplicados de producto en el mismo almacén
    add_index :inventories, [:product_id, :warehouse_id], unique: true
  end
end
