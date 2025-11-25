class CreatePaymentApplications < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_applications do |t|
      t.references :payment, null: false, foreign_key: true
      t.references :sale, null: false, foreign_key: true
      t.decimal :amount_applied, precision: 10, scale: 2, null: false
      t.text :notes

      t.timestamps
    end

    # Índices para consultas rápidas
    add_index :payment_applications, [ :payment_id, :sale_id ], unique: true
  end
end
