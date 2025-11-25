class CreatePurchaseItems < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_items do |t|
      t.references :purchase, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      # Cantidad en unidad de compra (tal como viene en la factura/proveedor)
      t.decimal :quantity, precision: 12, scale: 2, null: false
      t.decimal :unit_cost, precision: 12, scale: 2, null: false
      # Conversión usada en el momento de la compra (snapshot)
      # p. ej. si unit_conversion del producto era 12 (caja->botella), se guarda 12.000000
      t.decimal :conversion_factor, precision: 12, scale: 6, default: 1.0, null: false
      # Cantidad resultante en unidad de venta (snapshot = quantity * conversion_factor)
      t.decimal :quantity_sale_units, precision: 12, scale: 2, null: false

      t.timestamps
    end
    add_check_constraint :purchase_items, "quantity > 0", name: "chk_purchase_items_quantity_positive"
    add_check_constraint :purchase_items, "unit_cost >= 0", name: "chk_purchase_items_unit_cost_nonnegative"
    add_check_constraint :purchase_items, "conversion_factor > 0", name: "chk_purchase_items_conversion_positive"
    add_check_constraint :purchase_items, "quantity_sale_units > 0", name: "chk_purchase_items_quantity_sale_units_positive"
  end
end
