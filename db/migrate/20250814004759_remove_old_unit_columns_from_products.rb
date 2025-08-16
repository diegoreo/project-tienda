class RemoveOldUnitColumnsFromProducts < ActiveRecord::Migration[8.0]
  def change
    remove_column :products, :sale_unit, :string
    remove_column :products, :purchase_unit, :string
  end
end
