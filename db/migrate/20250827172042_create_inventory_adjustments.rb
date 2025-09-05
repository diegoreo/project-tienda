class CreateInventoryAdjustments < ActiveRecord::Migration[8.0]
  def change
    create_table :inventory_adjustments do |t|
      t.references :inventory, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 3, null: false 
      t.integer :adjustment_type, null: false, default: 0   # enum increase/decrease
      t.string :reason, null: false
      t.text :note
      t.string :performed_by, null: false   # ← en lugar de user_id, guardamos texto
      t.timestamps
    end
  end
end
