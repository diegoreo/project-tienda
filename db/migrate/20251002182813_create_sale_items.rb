class CreateSaleItems < ActiveRecord::Migration[8.0]
  def change
    create_table :sale_items do |t|
      t.references :sale, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 3, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :discount, precision: 10, scale: 2, default: 0.0
      t.decimal :subtotal, precision: 10, scale: 2, null: false
      
      t.timestamps
    end
  end
end
