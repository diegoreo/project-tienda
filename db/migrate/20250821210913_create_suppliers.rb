class CreateSuppliers < ActiveRecord::Migration[8.0]
  def change
    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :contact_info

      t.timestamps
    end

    add_index :suppliers, :name
  end
end
