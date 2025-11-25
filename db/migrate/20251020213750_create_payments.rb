class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :sale, null: true, foreign_key: true  # Puede ser null si es abono general
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.date :payment_date, null: false
      t.integer :payment_method, null: false, default: 0
      t.text :notes

      t.timestamps
    end

    add_index :payments, :payment_date
    add_index :payments, [ :customer_id, :payment_date ]
  end
end
