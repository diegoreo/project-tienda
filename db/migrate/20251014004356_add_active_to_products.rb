class AddActiveToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :active, :boolean, default: true, null: false
    add_index :products, :active
  end
end
