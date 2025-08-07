class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description
      t.decimal :price
      t.decimal :stock_quantity
      t.string :purchase_unit
      t.string :sale_unit
      t.decimal :unit_conversion
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
  end
end
