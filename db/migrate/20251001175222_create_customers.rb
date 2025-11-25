class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.text :address
      t.string :rfc
      t.decimal :credit_limit, precision: 10, scale: 2
      t.decimal :current_debt, precision: 10, scale: 2, default: 0.0, null: false
      t.integer :customer_type, default: 0, null: false
      t.text :notes

      t.timestamps
    end

    add_index :customers, :name
    add_index :customers, :phone
    add_index :customers, :email
    add_index :customers, :rfc
    add_index :customers, :customer_type
  end
end
