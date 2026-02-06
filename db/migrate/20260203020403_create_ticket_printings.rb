class CreateTicketPrintings < ActiveRecord::Migration[8.0]
  def change
    create_table :ticket_printings do |t|
      t.references :sale, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :print_number, null: false
      t.string :printer_name
      t.datetime :printed_at, null: false

      t.timestamps
    end
    
    add_index :ticket_printings, [:sale_id, :print_number], unique: true
  end
end
