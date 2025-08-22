class CreatePurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :purchases do |t|
      t.references :supplier, null: false, foreign_key: true
      t.references :warehouse, null: false, foreign_key: true
      t.date :purchase_date
      t.decimal :total, precision: 12, scale: 2, default: 0, null: false

      t.timestamps
    end
    add_index :purchases, :purchase_date
  end
end
