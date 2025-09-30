class AddFieldsToPurchaseItems < ActiveRecord::Migration[8.0]
  def change
    # Renombrar unit_cost a purchase_price
    rename_column :purchase_items, :unit_cost, :purchase_price

    # Agregar costo por pieza
    add_column :purchase_items, :cost_per_piece, :decimal, precision: 12, scale: 2, default: 0.0, null: false

    # Agregar subtotal
    add_column :purchase_items, :subtotal, :decimal, precision: 14, scale: 2, default: 0.0, null: false
  end
end
